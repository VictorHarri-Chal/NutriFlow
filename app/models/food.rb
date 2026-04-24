class Food < ApplicationRecord
  include PgSearch::Model

  CATEGORIES = %w[proteins grains vegetables fruits dairy beverages condiments other].freeze

  belongs_to :user
  has_many :day_foods, dependent: :destroy
  has_many :days, through: :day_foods
  has_many :shopping_list_items, dependent: :nullify
  has_and_belongs_to_many :food_labels, join_table: 'food_labels_foods'

  validates :name,     presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  validates :fats, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :carbs, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :sugars, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :proteins, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :calories, presence: true, numericality: { greater_than_or_equal_to: 0 }

  pg_search_scope :search_by_name,
  against: [:name],
  using: {
    tsearch: { prefix: true }
  }

  def self.ransackable_attributes(auth_object = nil)
    ["brand", "calories", "carbs", "fats", "name", "proteins", "sugars"]
  end
end
