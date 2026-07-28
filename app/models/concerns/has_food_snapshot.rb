# Feuille de log pointant un Food (DayFood, DayRecipeItem). Contrairement à
# HasFoodQuantity (qui lit le Food EN DIRECT et reste réservé aux templates
# comme RecipeItem), ce concern FIGE au save les valeurs/100g + le nom dans
# food_snapshot / food_name, et ne lit ensuite QUE le figé. Éditer ou supprimer
# le Food n'altère plus le log.
module HasFoodSnapshot
  extend ActiveSupport::Concern

  UNITS        = HasFoodQuantity::UNITS
  MAX_QUANTITY = HasFoodQuantity::MAX_QUANTITY

  included do
    belongs_to :food, optional: true
    validate :food_reference_must_resolve
    before_save :capture_food_snapshot, if: :should_capture_food_snapshot?
  end

  def grams_equivalent
    (quantity.to_f * HasFoodQuantity::UNIT_GRAM_MULTIPLIERS.fetch(unit.to_s, 1.0)).round(1)
  end

  def gram_factor = grams_equivalent / 100.0

  def total_calories      = scaled_from_snapshot("calories")
  def total_proteins      = scaled_from_snapshot("proteins")
  def total_carbs         = scaled_from_snapshot("carbs")
  def total_fats          = scaled_from_snapshot("fats")
  def total_sugars        = scaled_from_snapshot("sugars")
  def total_fiber         = scaled_from_snapshot("fiber", 2)
  def total_saturated_fat = scaled_from_snapshot("saturated_fat", 2)
  def total_salt          = scaled_from_snapshot("salt", 2)

  def scaled_micronutrients
    micros = food_snapshot&.dig("micronutrients")
    return {} if micros.blank?
    micros.transform_values { |v| (v.to_f * gram_factor).round(3) }
  end

  class_methods do
    # Valeurs POUR 100g figées à l'instant du log.
    def build_food_snapshot(food)
      {
        "calories"       => food.calories.to_f,
        "proteins"       => food.proteins.to_f,
        "carbs"          => food.carbs.to_f,
        "fats"           => food.fats.to_f,
        "sugars"         => food.sugars.to_f,
        "fiber"          => food.fiber.to_f,
        "saturated_fat"  => food.saturated_fat.to_f,
        "salt"           => food.salt.to_f,
        "micronutrients" => (food.micronutrients.presence || {}),
        "allergens"      => food.allergens.to_a,
        "traces"         => food.traces.to_a
      }
    end
  end

  private

  def scaled_from_snapshot(key, precision = 1)
    (food_snapshot.to_h[key].to_f * gram_factor).round(precision)
  end

  # Capture à la création (si non pré-rempli, ex. copy_yesterday qui copie le
  # snapshot figé), ou lors d'un vrai changement d'aliment sur un log existant.
  # On teste `food.present?` (pas seulement food_id) : un food_id périmé/forgé
  # (aliment supprimé entre l'ouverture du formulaire et le submit) résout à nil,
  # et capturer dessus planterait — la validation ci-dessous le rejette proprement.
  def should_capture_food_snapshot?
    food.present? && (food_snapshot.blank? || (persisted? && will_save_change_to_food_id?))
  end

  def capture_food_snapshot
    self.food_name     = food.name
    self.food_snapshot = self.class.build_food_snapshot(food)
  end

  # Un food_id fourni doit pointer un Food existant. Exception : un log déjà
  # détaché (food_id nil mais snapshot figé) reste valide sans aliment.
  def food_reference_must_resolve
    errors.add(:food_id, :invalid) if food_id.present? && food.blank?
  end
end
