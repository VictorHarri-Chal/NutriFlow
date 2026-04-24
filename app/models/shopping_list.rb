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

    pa = a.to_s.strip.match(/\A([\d.]+)\s*(\S*)\z/)
    pb = b.to_s.strip.match(/\A([\d.]+)\s*(\S*)\z/)

    return "#{a} + #{b}" unless pa && pb

    unit_a, unit_b = pa[2], pb[2]

    if unit_a == unit_b
      total = pa[1].to_f + pb[1].to_f
      n = total == total.to_i ? total.to_i : total
      unit_a.present? ? "#{n} #{unit_a}" : n.to_s
    else
      conv_a = UNIT_CONVERSIONS[unit_a]
      conv_b = UNIT_CONVERSIONS[unit_b]

      if conv_a && conv_b && conv_a[0] == conv_b[0]
        total = pa[1].to_f * conv_a[1] + pb[1].to_f * conv_b[1]
        n = total == total.to_i ? total.to_i : total
        "#{n} #{conv_a[0]}"
      else
        "#{a} + #{b}"
      end
    end
  end
end
