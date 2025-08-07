class Food < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  has_many :day_foods, dependent: :destroy
  has_many :days, through: :day_foods

  validates :name, presence: true
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
end
