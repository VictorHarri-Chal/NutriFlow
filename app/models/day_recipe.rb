class DayRecipe < ApplicationRecord
  include ValidatesSharedOwner

  belongs_to :day
  belongs_to :recipe
  belongs_to :day_food_group, optional: true
  has_many :day_recipe_items, dependent: :destroy, inverse_of: :day_recipe

  accepts_nested_attributes_for :day_recipe_items, allow_destroy: true, reject_if: :all_blank

  validates :quantity, presence: true, numericality: { greater_than: 0 }, unless: -> { use_recipe_quantity? || customized? }
  validates :recipe_id, presence: true
  validates_shared_owner :recipe, owner: :day
  validate :day_food_group_belongs_to_user, if: -> { day_food_group_id.present? && day.present? }
  validate :must_have_at_least_one_ingredient, if: :customized?

  private

  def day_food_group_belongs_to_user
    unless day.user.day_food_groups.exists?(day_food_group_id)
      errors.add(:day_food_group, :invalid)
    end
  end

  def must_have_at_least_one_ingredient
    if day_recipe_items.reject(&:marked_for_destruction?).empty?
      errors.add(:base, I18n.t("activerecord.errors.models.day_recipe.at_least_one_ingredient"))
    end
  end

  public

  def effective_quantity
    return day_recipe_items.sum(&:grams_equivalent).round(1) if customized?
    use_recipe_quantity? ? recipe.total_weight : quantity
  end

  def gram_factor
    total = recipe.total_weight.to_f
    return 0.0 if total.zero?

    effective_quantity / total
  end

  # Méthodes pour compatibilité avec DayFood
  def food
    recipe
  end

  def food_name
    recipe.name
  end

  def total_calories      = customized? ? customized_totals[:calories]      : (recipe.total_calories      * gram_factor).round(1)
  def total_proteins      = customized? ? customized_totals[:proteins]      : (recipe.total_proteins      * gram_factor).round(1)
  def total_carbs         = customized? ? customized_totals[:carbs]         : (recipe.total_carbs         * gram_factor).round(1)
  def total_fats          = customized? ? customized_totals[:fats]         : (recipe.total_fats          * gram_factor).round(1)
  def total_sugars        = customized? ? customized_totals[:sugars]        : (recipe.total_sugars        * gram_factor).round(1)
  def total_fiber         = customized? ? customized_totals[:fiber]         : (recipe.total_fiber         * gram_factor).round(1)
  def total_saturated_fat = customized? ? customized_totals[:saturated_fat] : (recipe.total_saturated_fat * gram_factor).round(1)
  def total_salt          = customized? ? customized_totals[:salt]          : (recipe.total_salt          * gram_factor).round(1)

  def total_weight
    effective_quantity
  end

  # Pour l'affichage dans les composants
  def display_quantity
    "#{effective_quantity} g"
  end

  private

  # Mémorisé comme Recipe#computed_totals : évite de re-parcourir day_recipe_items
  # une fois par macro, et arrondit une seule fois à la fin (au lieu de sommer des
  # valeurs déjà arrondies par ingrédient, qui pouvait produire des écarts de
  # précision entre les deux branches customized?/non-customized).
  def customized_totals
    @customized_totals ||= day_recipe_items.each_with_object(
      { calories: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, sugars: 0.0,
        fiber: 0.0, saturated_fat: 0.0, salt: 0.0 }
    ) do |item, acc|
      acc[:calories]      += item.total_calories
      acc[:proteins]      += item.total_proteins
      acc[:carbs]         += item.total_carbs
      acc[:fats]          += item.total_fats
      acc[:sugars]        += item.total_sugars
      acc[:fiber]         += item.total_fiber
      acc[:saturated_fat] += item.total_saturated_fat
      acc[:salt]          += item.total_salt
    end.transform_values { |v| v.round(1) }
  end
end
