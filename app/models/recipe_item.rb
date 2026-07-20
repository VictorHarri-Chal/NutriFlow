class RecipeItem < ApplicationRecord
  include HasFoodQuantity
  include ValidatesSharedOwner

  belongs_to :recipe

  validates :quantity, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: HasFoodQuantity::MAX_QUANTITY }
  validates :food_id, presence: true
  validates :unit, inclusion: { in: UNITS }
  validates_shared_owner :food, owner: :recipe
  validate :quantity_at_least_one_gram_equivalent

  private

  # The `quantity` column holds a raw number in whatever `unit` is selected
  # (g/kg/mL/L) — a plain `greater_than_or_equal_to: 1` on `quantity` itself
  # would reject a perfectly valid "0.5 kg" (= 500 g) entry. Enforce the
  # minimum on the gram-equivalent instead.
  def quantity_at_least_one_gram_equivalent
    return if quantity.blank? || errors[:quantity].any?
    errors.add(:quantity, :greater_than_or_equal_to, count: 1) if grams_equivalent < 1
  end
end
