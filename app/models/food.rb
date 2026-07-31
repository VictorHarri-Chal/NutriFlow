class Food < ApplicationRecord
  include PgSearch::Model

  CATEGORIES = %w[proteins grains vegetables fruits dairy beverages condiments supplements other].freeze

  belongs_to :user
  # day_foods/day_recipe_items snapshot their own name + macros at log time
  # (food_name/food_snapshot) — deleting the Food never erases logged history,
  # it just detaches the (now immutable) log from its source. recipe_items
  # is :destroy (not :restrict_with_error): Recipe is NOT snapshotted, it reads
  # the live Food, so a Recipe must never be left pointing at a nil ingredient.
  # FoodsController#destroy handles the recipe TEMPLATE removal explicitly
  # (confirms with the user first, and deletes any recipe left with zero
  # ingredients after this food is removed from it).
  has_many :day_foods, dependent: :nullify
  has_many :days, through: :day_foods
  has_many :recipe_items, dependent: :destroy
  has_many :day_recipe_items, dependent: :nullify
  has_many :shopping_list_items, dependent: :nullify
  has_and_belongs_to_many :food_labels, join_table: 'food_labels_foods'

  # Nutritional attributes whose change makes every referencing recipe's
  # denormalized totals stale (see #recompute_dependent_recipes).
  MACRO_ATTRIBUTES = %w[calories proteins carbs fats sugars fiber saturated_fat salt micronutrients].freeze

  before_validation :default_optional_macros_to_zero
  after_update :recompute_dependent_recipes, if: :saved_change_to_macros?

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

  def saved_change_to_macros?
    saved_changes.keys.intersect?(MACRO_ATTRIBUTES)
  end

  # Refresh the denormalized totals of every recipe using this food. Bounded to
  # this user's recipes (a food belongs to one user); recompute_totals! is a
  # plain update_columns, so no cascading callbacks fire.
  def recompute_dependent_recipes
    Recipe.where(id: RecipeItem.where(food_id: id).select(:recipe_id))
          .find_each(&:recompute_totals!)
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
