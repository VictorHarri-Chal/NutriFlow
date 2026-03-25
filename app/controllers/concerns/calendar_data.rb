module CalendarData
  extend ActiveSupport::Concern

  private

  def load_calendar_data(day)
    @day = day

    day_foods    = day.day_foods.includes(:food, :day_food_group)
    day_recipes  = day.day_recipes.includes(:recipe, :day_food_group)
    all_items    = day_foods + day_recipes

    @day_items_by_group      = all_items.group_by(&:day_food_group)
    @day_items_without_group = @day_items_by_group.delete(nil) || []
    @all_day_items           = all_items

    @total_calories = day.total_calories
    @total_proteins = day.total_proteins
    @total_carbs    = day.total_carbs
    @total_fats     = day.total_fats
    @total_sugars   = day.total_sugars

    @profile = current_user.profile
    return unless @profile&.weight.present?

    @daily_calorie_goal = @profile.calories_needed_for_goal
    @daily_protein_goal = @profile.daily_protein_goal
    @daily_fats_goal    = @profile.daily_fats_goal

    @calories_percentage = @daily_calorie_goal > 0 ? (@total_calories / @daily_calorie_goal.to_f * 100).round(1) : 0
    @proteins_percentage = @daily_protein_goal > 0 ? (@total_proteins / @daily_protein_goal.to_f * 100).round(1) : 0
    @fats_percentage     = @daily_fats_goal    > 0 ? (@total_fats     / @daily_fats_goal.to_f    * 100).round(1) : 0
  end
end
