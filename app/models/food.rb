class Food < ApplicationRecord
  include PgSearch::Model

  CATEGORIES = %w[proteins grains vegetables fruits dairy beverages condiments supplements other].freeze

  belongs_to :user
  has_many :day_foods, dependent: :destroy
  has_many :days, through: :day_foods
  has_many :recipe_items, dependent: :destroy
  has_many :shopping_list_items, dependent: :nullify
  has_and_belongs_to_many :food_labels, join_table: 'food_labels_foods'

  before_validation :default_optional_macros_to_zero

  validates :name,     presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  validates :calories, :proteins, :fats, :carbs, :sugars, :fiber, :saturated_fat, :salt,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

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
end
