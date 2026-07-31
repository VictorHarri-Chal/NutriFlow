class Recipe < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  has_many :recipe_items, dependent: :destroy
  has_many :foods, through: :recipe_items
  has_many :recipe_ratings, dependent: :destroy
  # Les DayRecipe sont des logs figés (day_recipe_items + snapshots) : supprimer
  # une recette les détache (recipe_id → NULL), l'historique reste intact.
  has_many :day_recipes, dependent: :nullify

  accepts_nested_attributes_for :recipe_items, allow_destroy: true, reject_if: :all_blank

  # Denormalized totals are refreshed after any recipe/item change (declared
  # AFTER accepts_nested_attributes_for so the items autosave runs first, and the
  # recompute reads the reconciled rows). Food-macro edits refresh them too, via
  # Food's cascade (see Food#recompute_dependent_recipes).
  after_save :recompute_totals!

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validate :must_have_at_least_one_ingredient

  def rating_for(user)
    find_rating(user)&.rating || 0
  end

  def rating_comment_for(user)
    find_rating(user)&.comment
  end

  pg_search_scope :search_by_name,
                  against: [:name],
                  using: {
                    tsearch: { prefix: true }
                  }

  def per_100g
    weight = total_weight.to_f
    factor = weight > 0 ? (100.0 / weight) : 0
    { calories:      (total_calories      * factor).round(1),
      proteins:      (total_proteins      * factor).round(1),
      carbs:         (total_carbs         * factor).round(1),
      fats:          (total_fats          * factor).round(1),
      sugars:        (total_sugars        * factor).round(1),
      fiber:         (total_fiber         * factor).round(1),
      saturated_fat: (total_saturated_fat * factor).round(1),
      salt:          (total_salt          * factor).round(1) }
  end

  def per_100g_micronutrients
    weight = total_weight.to_f
    factor = weight > 0 ? (100.0 / weight) : 0
    aggregated_micronutrients.transform_values { |v| (v * factor).round(2) }
  end

  # Read the denormalized columns (kept in sync by #recompute_totals!). Coerced
  # to Float to preserve the previous display type (Decimal#to_s uses sci notation).
  def total_calories      = self[:total_calories].to_f
  def total_proteins      = self[:total_proteins].to_f
  def total_carbs         = self[:total_carbs].to_f
  def total_fats          = self[:total_fats].to_f
  def total_sugars        = self[:total_sugars].to_f
  def total_weight        = self[:total_weight].to_f
  def total_fiber         = self[:total_fiber].to_f
  def total_saturated_fat = self[:total_saturated_fat].to_f
  def total_salt          = self[:total_salt].to_f

  def aggregated_micronutrients
    @aggregated_micronutrients ||= recipe_items.each_with_object({}) do |item, acc|
      item.scaled_micronutrients.each do |key, value|
        acc[key.to_s] = (acc[key.to_s] || 0) + value
      end
    end.transform_values { |v| v.round(2) }.reject { |_, v| v.zero? }
  end

  def aggregated_allergens
    @aggregated_allergens ||= recipe_items.flat_map { |i| i.food.allergens.to_a }.uniq.sort
  end

  def aggregated_traces
    @aggregated_traces ||= recipe_items.flat_map { |i| i.food.traces.to_a }.uniq.sort
  end


  # Recomputes and persists the denormalized totals from the current items and
  # their foods. update_columns fires no callbacks (no recursion); the items are
  # re-read fresh from the DB (bypassing any stale association cache) with food
  # preloaded, so it reflects the committed state on every trigger path.
  def recompute_totals!
    t = compute_live_totals(recipe_items.includes(:food).to_a)
    update_columns(
      total_calories: t[:calories], total_proteins: t[:proteins], total_carbs: t[:carbs],
      total_fats: t[:fats], total_sugars: t[:sugars], total_weight: t[:weight],
      total_fiber: t[:fiber], total_saturated_fat: t[:saturated_fat], total_salt: t[:salt]
    )
  end

  private

  # Live aggregation from items — the source of truth the columns cache.
  def compute_live_totals(items)
    items.each_with_object(
      { calories: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, sugars: 0.0, weight: 0.0,
        fiber: 0.0, saturated_fat: 0.0, salt: 0.0 }
    ) do |item, acc|
      acc[:calories]      += item.total_calories
      acc[:proteins]      += item.total_proteins
      acc[:carbs]         += item.total_carbs
      acc[:fats]          += item.total_fats
      acc[:sugars]        += item.total_sugars
      acc[:weight]        += item.grams_equivalent
      acc[:fiber]         += item.total_fiber
      acc[:saturated_fat] += item.total_saturated_fat
      acc[:salt]          += item.total_salt
    end.transform_values { |v| v.round(1) }
  end

  def find_rating(user)
    if recipe_ratings.loaded?
      recipe_ratings.detect { |r| r.user_id == user.id }
    else
      recipe_ratings.find_by(user: user)
    end
  end

  def must_have_at_least_one_ingredient
    if recipe_items.reject(&:marked_for_destruction?).empty?
      errors.add(:base, I18n.t("activerecord.errors.models.recipe.at_least_one_ingredient"))
    end
  end
end
