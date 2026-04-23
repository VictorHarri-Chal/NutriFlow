# frozen_string_literal: true

# Computes all calendar data for a single day and returns a plain hash.
# Extracted from the CalendarData concern to make this logic testable in isolation.
#
# Usage:
#   result = CalendarDataLoader.new(current_user, day).call
#   result.each { |key, value| instance_variable_set("@#{key}", value) }
#
class CalendarDataLoader
  def initialize(user, day)
    @user = user
    @day  = day
  end

  def call
    load_items
    load_profile_goals
    build_result
  end

  private

  # ── Items ────────────────────────────────────────────────────────────────────

  def load_items
    day_foods   = @day.day_foods.includes(:food, :day_food_group)
    day_recipes = @day.day_recipes.includes(:day_food_group, recipe: { recipe_items: :food })
    @all_items  = day_foods + day_recipes

    by_group                = @all_items.group_by(&:day_food_group)
    @day_items_without_group = by_group.delete(nil) || []
    @day_items_by_group      = by_group

    totals = @all_items.each_with_object(
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
  end

  # ── Profile & goals ──────────────────────────────────────────────────────────

  def load_profile_goals
    @profile    = @user.profile
    @has_foods   = @user.foods.exists?
    @has_recipes = @user.recipes.exists?

    return unless @profile&.weight.present? && @profile.bmr

    effective_steps  = @day.effective_steps(@profile)
    job_neat         = Profile::JOB_NEAT_KCAL[@profile.job_activity_level.to_sym] ||
                       Profile::JOB_NEAT_KCAL[:light_activity]
    steps_kcal       = @profile.neat_from_steps(effective_steps)
    workout_kcal     = @day.workout_calories_total
    tdee             = @profile.bmr + job_neat + steps_kcal + workout_kcal
    multiplier       = Profile::GOAL_MULTIPLIERS[@profile.goal.to_sym] || 1.0

    @tdee_breakdown = {
      bmr:          @profile.bmr,
      job_neat:     job_neat,
      steps_kcal:   steps_kcal,
      steps_count:  effective_steps,
      steps_custom: @day.steps.present?,
      workout_kcal: workout_kcal,
      tdee:         tdee,
      multiplier:   multiplier,
      goal_delta:   (tdee * multiplier - tdee).round
    }

    @daily_calorie_goal = (tdee * multiplier).round
    @daily_protein_goal = @profile.daily_protein_goal
    @daily_fats_goal    = @profile.daily_fats_goal
    @daily_carbs_goal   = @profile.daily_carbs_goal(day: @day)

    return unless @daily_calorie_goal

    @calories_percentage = @daily_calorie_goal > 0 ? (@total_calories / @daily_calorie_goal.to_f * 100).round(1) : 0
    @proteins_percentage = @daily_protein_goal > 0 ? (@total_proteins / @daily_protein_goal.to_f * 100).round(1) : 0
    @fats_percentage     = @daily_fats_goal    > 0 ? (@total_fats     / @daily_fats_goal.to_f    * 100).round(1) : 0
    @carbs_percentage    = @daily_carbs_goal && @daily_carbs_goal > 0 ? (@total_carbs / @daily_carbs_goal.to_f * 100).round(1) : 0
  end

  # ── Result ───────────────────────────────────────────────────────────────────

  def build_result
    {
      day:                     @day,
      day_items_by_group:      @day_items_by_group,
      day_items_without_group: @day_items_without_group,
      all_day_items:           @all_items,
      total_calories:          @total_calories,
      total_proteins:          @total_proteins,
      total_carbs:             @total_carbs,
      total_fats:              @total_fats,
      total_sugars:            @total_sugars,
      has_foods:               @has_foods,
      has_recipes:             @has_recipes,
      profile:                 @profile,
      tdee_breakdown:          @tdee_breakdown,
      daily_calorie_goal:      @daily_calorie_goal,
      daily_protein_goal:      @daily_protein_goal,
      daily_fats_goal:         @daily_fats_goal,
      daily_carbs_goal:        @daily_carbs_goal,
      calories_percentage:     @calories_percentage,
      proteins_percentage:     @proteins_percentage,
      fats_percentage:         @fats_percentage,
      carbs_percentage:        @carbs_percentage
    }
  end
end
