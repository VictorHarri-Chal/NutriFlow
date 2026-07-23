class DayRecipeItem < ApplicationRecord
  include HasFoodQuantity
  include ValidatesSharedOwner

  belongs_to :day_recipe

  validates :quantity, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: HasFoodQuantity::MAX_QUANTITY }
  validates :food_id, presence: true
  validates :unit, inclusion: { in: UNITS }
  validates_shared_owner :food, owner: -> { day_recipe&.day }
  validate :quantity_at_least_one_gram_equivalent

  private

  # See RecipeItem#quantity_at_least_one_gram_equivalent — `quantity` is a raw
  # number in whatever `unit` is selected (g/kg/mL/L), so the minimum must be
  # enforced on the gram-equivalent, not the raw column value.
  def quantity_at_least_one_gram_equivalent
    return if quantity.blank? || errors[:quantity].any?
    errors.add(:quantity, :greater_than_or_equal_to, count: 1) if grams_equivalent < 1
  end
end
