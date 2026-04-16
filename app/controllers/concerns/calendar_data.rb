module CalendarData
  extend ActiveSupport::Concern

  private

  def load_month_heatmap(date)
    start_of_month = date.beginning_of_month
    end_of_month   = date.end_of_month

    month_days = current_user.days
                   .where(date: start_of_month..end_of_month)
                   .includes(day_foods: :food, day_recipes: { recipe: { recipe_items: :food } })

    @month_heatmap = month_days.each_with_object({}) do |d, h|
      foods_cals   = d.day_foods.sum(&:total_calories)
      recipes_cals = d.day_recipes.sum(&:total_calories)
      h[d.date] = (foods_cals + recipes_cals).round
    end

    @heatmap_start = start_of_month
    @heatmap_end   = end_of_month
  end

  def load_calendar_data(day)
    @day = day

    day_foods    = day.day_foods.includes(:food, :day_food_group)
    day_recipes  = day.day_recipes.includes(:day_food_group, recipe: { recipe_items: :food })
    all_items    = day_foods + day_recipes

    @day_items_by_group      = all_items.group_by(&:day_food_group)
    @day_items_without_group = @day_items_by_group.delete(nil) || []
    @all_day_items           = all_items

    totals = all_items.each_with_object(
      { calories: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, sugars: 0.0 }
    ) do |item, acc|
      acc[:calories] += item.total_calories
      acc[:proteins] += item.total_proteins
      acc[:carbs]    += item.total_carbs
      acc[:fats]     += item.total_fats
      acc[:sugars]   += item.total_sugars
    end

    @total_calories = totals[:calories].round(1)
    @total_proteins = totals[:proteins].round(1)
    @total_carbs    = totals[:carbs].round(1)
    @total_fats     = totals[:fats].round(1)
    @total_sugars   = totals[:sugars].round(1)

    @has_foods   = current_user.foods.exists?
    @has_recipes = current_user.recipes.exists?

    @profile = current_user.profile
    return unless @profile&.weight.present?

    @daily_calorie_goal = @profile.calories_needed_for_goal
    @daily_protein_goal = @profile.daily_protein_goal
    @daily_fats_goal    = @profile.daily_fats_goal
    @daily_carbs_goal   = @profile.daily_carbs_goal

    return unless @daily_calorie_goal

    @calories_percentage = @daily_calorie_goal > 0 ? (@total_calories / @daily_calorie_goal.to_f * 100).round(1) : 0
    @proteins_percentage = @daily_protein_goal > 0 ? (@total_proteins / @daily_protein_goal.to_f * 100).round(1) : 0
    @fats_percentage     = @daily_fats_goal    > 0 ? (@total_fats     / @daily_fats_goal.to_f    * 100).round(1) : 0
    @carbs_percentage    = @daily_carbs_goal && @daily_carbs_goal > 0 ? (@total_carbs / @daily_carbs_goal.to_f * 100).round(1) : 0
  end
end
