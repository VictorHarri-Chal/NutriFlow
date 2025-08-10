class DayFoodGroupComponent < ApplicationComponent
  def initialize(day_food_group:, day_foods:)
    @day_food_group = day_food_group
    @day_foods = day_foods
  end

  private

  attr_reader :day_food_group, :day_foods

  def group_totals
    {
      calories: day_foods.sum(&:total_calories),
      proteins: day_foods.sum(&:total_proteins),
      carbs: day_foods.sum(&:total_carbs),
      fats: day_foods.sum(&:total_fats),
      sugars: day_foods.sum(&:total_sugars)
    }
  end
end
