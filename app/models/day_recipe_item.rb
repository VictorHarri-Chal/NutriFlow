class DayRecipeItem < ApplicationRecord
  include HasFoodQuantity
  include ValidatesSharedOwner

  belongs_to :day_recipe

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :food_id, presence: true
  validates :unit, inclusion: { in: UNITS }
  validates_shared_owner :food, owner: -> { day_recipe&.day }
end
