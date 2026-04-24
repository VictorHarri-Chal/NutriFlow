class RecipeItem < ApplicationRecord
  UNITS = %w[g kg mL L].freeze

  UNIT_GRAM_MULTIPLIERS = {
    "g"  => 1.0,
    "kg" => 1000.0,
    "mL" => 1.0,
    "L"  => 1000.0
  }.freeze

  belongs_to :recipe
  belongs_to :food

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :food_id, presence: true
  validates :unit, inclusion: { in: UNITS }

  def grams_equivalent = quantity.to_f * UNIT_GRAM_MULTIPLIERS.fetch(unit.to_s, 1.0)
  def gram_factor      = grams_equivalent / 100.0
  def total_calories   = (food.calories.to_f * gram_factor).round(1)
  def total_proteins   = (food.proteins.to_f * gram_factor).round(1)
  def total_carbs      = (food.carbs.to_f    * gram_factor).round(1)
  def total_fats       = (food.fats.to_f     * gram_factor).round(1)
  def total_sugars     = (food.sugars.to_f   * gram_factor).round(1)
end
