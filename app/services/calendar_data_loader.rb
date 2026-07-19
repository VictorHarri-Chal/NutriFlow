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
    @day  = Day.includes(:workout_sessions, cardio_sessions: :cardio_blocks).find(day.id)
  end

  def call
    load_items
    load_profile_goals
    load_micronutrients
    build_result
  end

  private

  # ── Items ────────────────────────────────────────────────────────────────────

  def load_items
    day_foods   = @day.day_foods.includes(:food, :day_food_group)
    day_recipes = @day.day_recipes.includes(:day_food_group, recipe: { recipe_items: :food }, day_recipe_items: :food)
    @all_items  = day_foods + day_recipes

    by_group                = @all_items.group_by(&:day_food_group)
    @day_items_without_group = by_group.delete(nil) || []
    @day_items_by_group      = by_group

    totals = @all_items.each_with_object(
      { calories: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, sugars: 0.0,
        fiber: 0.0, saturated_fat: 0.0, salt: 0.0 }
    ) do |item, acc|
      acc[:calories]      += item.total_calories
      acc[:proteins]      += item.total_proteins
      acc[:carbs]         += item.total_carbs
      acc[:fats]          += item.total_fats
      acc[:sugars]        += item.total_sugars
      acc[:fiber]         += item.total_fiber
      acc[:saturated_fat] += item.total_saturated_fat
      acc[:salt]          += item.total_salt
    end

    @total_calories      = totals[:calories].round(1)
    @total_proteins      = totals[:proteins].round(1)
    @total_carbs         = totals[:carbs].round(1)
    @total_fats          = totals[:fats].round(1)
    @total_sugars        = totals[:sugars].round(1)
    @total_fiber         = totals[:fiber].round(1)
    @total_saturated_fat = totals[:saturated_fat].round(1)
    @total_salt          = totals[:salt].round(1)
  end

  # ── Profile & goals ──────────────────────────────────────────────────────────

  def load_profile_goals
    @profile     = @user.profile
    @has_foods   = @user.foods.exists?
    @has_recipes = @user.recipes.exists?

    goal_delta      = @profile.daily_calorie_delta
    @tdee_breakdown = @profile.tdee_breakdown(day: @day).merge(goal_delta: goal_delta)
    tdee            = @tdee_breakdown[:tdee]

    @daily_calorie_goal = (tdee + goal_delta).round
    @daily_protein_goal = @profile.daily_protein_goal
    @daily_fats_goal    = @profile.daily_fats_goal(day: @day)
    @daily_carbs_goal   = @profile.daily_carbs_goal(day: @day)

    return unless @daily_calorie_goal

    @calories_percentage = @daily_calorie_goal > 0 ? (@total_calories / @daily_calorie_goal.to_f * 100).round(1) : 0
    @proteins_percentage = @daily_protein_goal > 0 ? (@total_proteins / @daily_protein_goal.to_f * 100).round(1) : 0
    @fats_percentage     = @daily_fats_goal    > 0 ? (@total_fats     / @daily_fats_goal.to_f    * 100).round(1) : 0
    @carbs_percentage    = @daily_carbs_goal && @daily_carbs_goal > 0 ? (@total_carbs / @daily_carbs_goal.to_f * 100).round(1) : 0
  end

  # ── Micronutrients ───────────────────────────────────────────────────────────

  def load_micronutrients
    @micronutrient_coverage = @day.micronutrient_coverage
    @micronutrient_week_start = @day.date.beginning_of_week
    @micronutrient_week_end   = @day.date.end_of_week
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
      total_fiber:             @total_fiber,
      total_saturated_fat:     @total_saturated_fat,
      total_salt:              @total_salt,
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
      carbs_percentage:        @carbs_percentage,
      micronutrient_coverage:   @micronutrient_coverage,
      micronutrient_week_start: @micronutrient_week_start,
      micronutrient_week_end:   @micronutrient_week_end
    }
  end
end
