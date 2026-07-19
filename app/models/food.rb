class Food < ApplicationRecord
  include PgSearch::Model

  CATEGORIES = %w[proteins grains vegetables fruits dairy beverages condiments supplements other].freeze

  belongs_to :user
  # :restrict_with_error, not :destroy — deleting a Food must never silently
  # erase logged history or gut a recipe out from under the user. Blocking the
  # deletion (see FoodsController#destroy) forces removing it from those places
  # first, deliberately.
  has_many :day_foods, dependent: :restrict_with_error
  has_many :days, through: :day_foods
  has_many :recipe_items, dependent: :restrict_with_error
  has_many :day_recipe_items, dependent: :restrict_with_error
  has_many :shopping_list_items, dependent: :nullify
  has_and_belongs_to_many :food_labels, join_table: 'food_labels_foods'

  before_validation :default_optional_macros_to_zero

  validates :name,     presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  validates :calories, :proteins, :fats, :carbs, :sugars, :fiber, :saturated_fat, :salt,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :micronutrients_are_valid

  pg_search_scope :search_by_name,
  against: [:name],
  using: {
    tsearch: { prefix: true }
  }

  def self.ransackable_attributes(auth_object = nil)
    ["brand", "calories", "carbs", "fats", "name", "proteins", "sugars"]
  end

  def self.frequently_used(user:, excluding_ids: [], limit: 15, since: 1.year.ago)
    user.foods
        .joins(day_foods: :day)
        .where(days: { date: since.to_date.. })
        .where.not(id: excluding_ids)
        .group("foods.id")
        .order(Arel.sql("COUNT(day_foods.id) DESC, foods.name ASC"))
        .limit(limit)
  end

  def source
    self[:source]&.to_sym || :manual
  end

  private

  def default_optional_macros_to_zero
    self.calories      ||= 0
    self.proteins      ||= 0
    self.fats          ||= 0
    self.carbs         ||= 0
    self.sugars        ||= 0
    self.fiber         ||= 0
    self.saturated_fat ||= 0
    self.salt          ||= 0
  end

  # Plafond de bon sens (aucun micronutriment par 100g ne s'en approche jamais
  # réellement) qui empêche une valeur combinée à une quantité loggée énorme
  # de dépasser Float::MAX et de produire Infinity, valeur que Statistics
  # échoue ensuite à sérialiser en JSON.
  MICRONUTRIENT_MAX_VALUE = 100_000

  def micronutrients_are_valid
    return if micronutrients.blank?

    valid_keys = Micronutrient::KEYS.map(&:to_s)
    micronutrients.each do |key, value|
      unless valid_keys.include?(key.to_s)
        errors.add(:micronutrients, :unknown_key, key: key)
        next
      end
      unless value.is_a?(Numeric) && value.to_f > 0
        errors.add(:micronutrients, :invalid_value, key: key)
        next
      end
      if value.to_f > MICRONUTRIENT_MAX_VALUE
        errors.add(:micronutrients, :value_out_of_range, key: key)
      end
    end
  end
end
