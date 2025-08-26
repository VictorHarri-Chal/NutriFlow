class Recipe < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  has_many :recipe_items, dependent: :destroy
  has_many :foods, through: :recipe_items

  accepts_nested_attributes_for :recipe_items, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validate :must_have_at_least_one_ingredient

  pg_search_scope :search_by_name,
                  against: [:name],
                  using: {
                    tsearch: { prefix: true }
                  }

  def total_calories = recipe_items.to_a.sum(&:total_calories).round(1)
  def total_proteins = recipe_items.to_a.sum(&:total_proteins).round(1)
  def total_carbs    = recipe_items.to_a.sum(&:total_carbs).round(1)
  def total_fats     = recipe_items.to_a.sum(&:total_fats).round(1)
  def total_sugars   = recipe_items.to_a.sum(&:total_sugars).round(1)

  private

  def must_have_at_least_one_ingredient
    if recipe_items.reject(&:marked_for_destruction?).empty?
      errors.add(:base, "Au moins un ingrédient est requis")
    end
  end
end
