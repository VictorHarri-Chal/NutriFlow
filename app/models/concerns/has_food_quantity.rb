module HasFoodQuantity
  extend ActiveSupport::Concern

  UNITS = %w[g kg mL L].freeze

  # Plafond de bon sens sur la quantité loggée (dans son unité native) — sans
  # lui, une quantité extrême combinée à une valeur nutritionnelle élevée peut
  # dépasser Float::MAX lors du scaling et produire Infinity.
  MAX_QUANTITY = 100_000

  UNIT_GRAM_MULTIPLIERS = {
    "g"  => 1.0,
    "kg" => 1000.0,
    "mL" => 1.0,
    "L"  => 1000.0
  }.freeze

  included do
    belongs_to :food
  end

  def grams_equivalent = (quantity.to_f * UNIT_GRAM_MULTIPLIERS.fetch(unit.to_s, 1.0)).round(1)
  def gram_factor      = grams_equivalent / 100.0
  def total_calories      = (food.calories.to_f      * gram_factor).round(1)
  def total_proteins      = (food.proteins.to_f      * gram_factor).round(1)
  def total_carbs         = (food.carbs.to_f         * gram_factor).round(1)
  def total_fats          = (food.fats.to_f          * gram_factor).round(1)
  def total_sugars        = (food.sugars.to_f        * gram_factor).round(1)
  def total_fiber         = (food.fiber.to_f         * gram_factor).round(2)
  def total_saturated_fat = (food.saturated_fat.to_f * gram_factor).round(2)
  def total_salt          = (food.salt.to_f          * gram_factor).round(2)

  def scaled_micronutrients
    return {} unless food.micronutrients.present?
    food.micronutrients.transform_values { |v| (v.to_f * gram_factor).round(3) }
  end
end
