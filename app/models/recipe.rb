class Recipe < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  has_many :recipe_items, dependent: :destroy
  has_many :foods, through: :recipe_items
  has_many :recipe_ratings, dependent: :destroy

  accepts_nested_attributes_for :recipe_items, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
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

  def total_calories = computed_totals[:calories]
  def total_proteins = computed_totals[:proteins]
  def total_carbs    = computed_totals[:carbs]
  def total_fats     = computed_totals[:fats]
  def total_sugars   = computed_totals[:sugars]
  def total_weight   = computed_totals[:weight]


  private

  def computed_totals
    @computed_totals ||= recipe_items.each_with_object(
      { calories: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, sugars: 0.0, weight: 0.0 }
    ) do |item, acc|
      acc[:calories] += item.total_calories
      acc[:proteins] += item.total_proteins
      acc[:carbs]    += item.total_carbs
      acc[:fats]     += item.total_fats
      acc[:sugars]   += item.total_sugars
      acc[:weight]   += item.quantity.to_f
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
