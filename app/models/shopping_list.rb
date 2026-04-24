class ShoppingList < ApplicationRecord
  belongs_to :user
  has_many :shopping_list_items, -> { order(position: :asc, created_at: :asc) },
           dependent: :destroy

  validates :name, presence: true

  # Items groupés par catégorie ; nil → "other" ; unchecked first within each group
  def items_by_category
    sorted = shopping_list_items.sort_by { |i| [i.checked? ? 1 : 0, i.created_at] }
    sorted.group_by { |i| i.category.presence || "other" }
  end

  def unchecked_count
    shopping_list_items.where(checked: false).count
  end

  # Adds a food to the list, or merges its quantity with an existing entry.
  # Matches by food_id first, then by normalized name for manual entries.
  # Returns [item, :merged] or [item, :created]
  def add_or_merge_item(food:, name:, quantity: nil, category: nil)
    existing = if food
      shopping_list_items.find_by(food_id: food.id)
    else
      shopping_list_items.find_by("LOWER(TRIM(name)) = ?", name.to_s.strip.downcase)
    end

    if existing
      existing.update!(quantity: merge_quantities(existing.quantity, quantity))
      [existing, :merged]
    else
      item = shopping_list_items.create!(food: food, name: name, quantity: quantity, category: category)
      [item, :created]
    end
  end

  private

  # Unit conversion table: maps a unit to [canonical_unit, factor_to_canonical]
  UNIT_CONVERSIONS = {
    "g"  => ["g",  1],
    "kg" => ["g",  1000],
    "ml" => ["mL", 1],
    "mL" => ["mL", 1],
    "l"  => ["mL", 1000],
    "L"  => ["mL", 1000]
  }.freeze

  # Merges two quantity strings:
  #   - Same unit          → sum
  #   - One blank          → keep the other
  #   - Compatible units   → convert to base unit (g or mL) and sum
  #   - Incompatible units → "a + b"
  def merge_quantities(a, b)
    return a if b.blank?
    return b if a.blank?

    pb = b.to_s.strip.match(/\A([\d.]+)\s*(\S*)\z/)
    return "#{a} + #{b}" unless pb

    unit_b = pb[2]
    val_b  = pb[1].to_f
    conv_b = UNIT_CONVERSIONS[unit_b]

    # Split compound quantities ("500 g + 90 mL") into components and try
    # to merge b into the first compatible component.
    components = a.to_s.split(" + ").map(&:strip)
    merged     = false

    new_components = components.map do |comp|
      next comp if merged

      pa = comp.match(/\A([\d.]+)\s*(\S*)\z/)
      next comp unless pa

      unit_a = pa[2]
      val_a  = pa[1].to_f
      conv_a = UNIT_CONVERSIONS[unit_a]

      if unit_a == unit_b
        total  = val_a + val_b
        n      = total % 1 == 0 ? total.to_i : total
        merged = true
        unit_a.present? ? "#{n} #{unit_a}" : n.to_s
      elsif conv_a && conv_b && conv_a[0] == conv_b[0]
        total  = val_a * conv_a[1] + val_b * conv_b[1]
        n      = total % 1 == 0 ? total.to_i : total
        merged = true
        "#{n} #{conv_a[0]}"
      else
        comp
      end
    end

    merged ? new_components.join(" + ") : "#{a} + #{b}"
  end
end
