class RecipeItem < ApplicationRecord
  belongs_to :recipe
  belongs_to :food

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :food_id, presence: true

  def gram_factor = quantity.to_f / 100.0
  def total_calories = (food.calories.to_f  * gram_factor).round(1)
  def total_proteins = (food.proteins.to_f  * gram_factor).round(1)
  def total_carbs    = (food.carbs.to_f     * gram_factor).round(1)
  def total_fats     = (food.fats.to_f      * gram_factor).round(1)
  def total_sugars   = (food.sugars.to_f    * gram_factor).round(1)
end
