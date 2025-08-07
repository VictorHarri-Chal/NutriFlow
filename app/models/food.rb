class Food < ApplicationRecord
  has_many :day_foods, dependent: :destroy
  has_many :days, through: :day_foods

  validates :name, presence: true
  validates :fats, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :carbs, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :sugars, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :proteins, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :calories, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
