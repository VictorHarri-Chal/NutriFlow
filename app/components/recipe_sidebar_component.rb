# frozen_string_literal: true

class RecipeSidebarComponent < ApplicationComponent
  def initialize(recipe:, current_user:, times_cooked: 0, last_cooked_date: nil)
    @recipe          = recipe
    @current_user    = current_user
    @times_cooked    = times_cooked
    @last_cooked_date = last_cooked_date
  end

  private

  attr_reader :recipe, :current_user

  def total_macro_kcal
    @total_macro_kcal ||= (recipe.total_proteins * 4) + (recipe.total_carbs * 4) + (recipe.total_fats * 9)
  end

  def protein_pct
    return 0 if total_macro_kcal.zero?
    (recipe.total_proteins * 4 / total_macro_kcal * 100).round
  end

  def carbs_pct
    return 0 if total_macro_kcal.zero?
    (recipe.total_carbs * 4 / total_macro_kcal * 100).round
  end

  def fat_pct
    return 0 if total_macro_kcal.zero?
    (recipe.total_fats * 9 / total_macro_kcal * 100).round
  end

  def micronutrients
    @micronutrients ||= recipe.aggregated_micronutrients
  end

  def ordered_micronutrients
    goals = weekly_goals
    Micronutrient::ALL.filter_map do |entry|
      total_value = micronutrients[entry.key.to_s]
      next unless total_value.present? && total_value != 0

      per_100g_value = per_100g_micronutrients[entry.key.to_s].to_f
      goal = goals[entry.key]

      { key: entry.key, unit: entry.unit,
        total_value: total_value, per_100g_value: per_100g_value,
        total_coverage_pct:    coverage_pct(total_value, goal),
        per_100g_coverage_pct: coverage_pct(per_100g_value, goal) }
    end
  end

  def allergens
    @allergens ||= recipe.aggregated_allergens
  end

  def traces
    @traces ||= recipe.aggregated_traces
  end

  def per_100g_micronutrients
    @per_100g_micronutrients ||= recipe.per_100g_micronutrients
  end

  def weekly_goals
    @weekly_goals ||= current_user.profile&.weekly_micronutrient_goals || {}
  end

  def coverage_pct(value, goal)
    return nil unless goal && goal > 0
    (value.to_f / goal * 100).round
  end

  attr_reader :times_cooked, :last_cooked_date
end
