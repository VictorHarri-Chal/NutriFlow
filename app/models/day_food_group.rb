class DayFoodGroup < ApplicationRecord
  belongs_to :user
  has_many :day_foods, dependent: :nullify
  has_many :day_recipes, dependent: :nullify

  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { scope: :user_id }

  scope :for_user, ->(user) { where(user: user) }

  before_destroy :move_items_to_ungrouped

  private

  def move_items_to_ungrouped
    day_foods.update_all(day_food_group_id: nil)
    day_recipes.update_all(day_food_group_id: nil)
  end
end
