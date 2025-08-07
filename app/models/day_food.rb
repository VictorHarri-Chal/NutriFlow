class DayFood < ApplicationRecord
  belongs_to :day
  belongs_to :food

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  def total_calories
    (food.calories * quantity).round(1)
  end

  def total_proteins
    (food.proteins * quantity).round(1)
  end

  def total_carbs
    (food.carbs * quantity).round(1)
  end

  def total_fats
    (food.fats * quantity).round(1)
  end

  def total_sugars
    (food.sugars * quantity).round(1)
  end
end
