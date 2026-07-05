class Recipe < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  has_many :recipe_items, dependent: :destroy
  has_many :foods, through: :recipe_items
  has_many :recipe_ratings, dependent: :destroy

  accepts_nested_attributes_for :recipe_items, allow_destroy: true, reject_if: :all_blank

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

  def total_calories      = computed_totals[:calories]
  def total_proteins      = computed_totals[:proteins]
  def total_carbs         = computed_totals[:carbs]
  def total_fats          = computed_totals[:fats]
  def total_sugars        = computed_totals[:sugars]
  def total_weight        = computed_totals[:weight]
  def total_fiber         = computed_totals[:fiber]
  def total_saturated_fat = computed_totals[:saturated_fat]
  def total_salt          = computed_totals[:salt]

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


  private

  def computed_totals
    @computed_totals ||= recipe_items.each_with_object(
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
