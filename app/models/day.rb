class Day < ApplicationRecord
  belongs_to :user
  has_many :day_foods, dependent: :destroy
  has_many :foods, through: :day_foods
  has_many :day_recipes, dependent: :destroy
  has_many :recipes, through: :day_recipes

  validates :date, presence: true, uniqueness: { scope: :user_id }

  scope :for_date, ->(date) { where(date: date) }

  def total_calories
    day_foods.sum(&:total_calories) + day_recipes.sum(&:total_calories)
  end

  def total_proteins
    day_foods.sum(&:total_proteins) + day_recipes.sum(&:total_proteins)
  end

  def total_carbs
    day_foods.sum(&:total_carbs) + day_recipes.sum(&:total_carbs)
  end

  def total_fats
    day_foods.sum(&:total_fats) + day_recipes.sum(&:total_fats)
  end

  def total_sugars
    day_foods.sum(&:total_sugars) + day_recipes.sum(&:total_sugars)
  end
end
