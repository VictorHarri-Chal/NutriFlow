class DayFood < ApplicationRecord
  belongs_to :day
  belongs_to :food
  belongs_to :day_food_group, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  def gram_factor
    quantity / 100.0
  end

  def total_calories
    (food.calories * gram_factor).round(1)
  end

  def total_proteins
    (food.proteins * gram_factor).round(1)
  end

  def total_carbs
    (food.carbs * gram_factor).round(1)
  end

  def total_fats
    (food.fats * gram_factor).round(1)
  end

  def total_sugars
    (food.sugars * gram_factor).round(1)
  end

  # Pour la cohérence avec DayRecipe
  def food_name
    food.name
  end

  def display_quantity
    "#{quantity} g"
  end
end
