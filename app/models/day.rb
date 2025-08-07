class Day < ApplicationRecord
  has_many :day_foods, dependent: :destroy
  has_many :foods, through: :day_foods

  validates :date, presence: true, uniqueness: true

  scope :for_date, ->(date) { where(date: date) }

  def total_calories
    day_foods.sum(&:total_calories)
  end

  def total_proteins
    day_foods.sum(&:total_proteins)
  end

  def total_carbs
    day_foods.sum(&:total_carbs)
  end

  def total_fats
    day_foods.sum(&:total_fats)
  end

  def total_sugars
    day_foods.sum(&:total_sugars)
  end
end
