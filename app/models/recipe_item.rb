class RecipeItem < ApplicationRecord
  include HasFoodQuantity
  include ValidatesSharedOwner

  belongs_to :recipe

  validates :quantity, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: HasFoodQuantity::MAX_QUANTITY }
  validates :food_id, presence: true
  validates :unit, inclusion: { in: UNITS }
  validates_shared_owner :food, owner: :recipe
end
