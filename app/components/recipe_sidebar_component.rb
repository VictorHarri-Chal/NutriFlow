# frozen_string_literal: true

class RecipeSidebarComponent < ApplicationComponent
  def initialize(recipe:, current_user:)
    @recipe = recipe
    @current_user = current_user
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

  # Grams of protein per 100 kcal — key fitness metric
  def protein_density
    return 0 if recipe.total_calories.zero?
    (recipe.total_proteins / recipe.total_calories * 100).round(1)
  end

  def times_cooked
    @times_cooked ||= DayRecipe
      .joins(:day)
      .where(days: { user_id: current_user.id }, recipe_id: recipe.id)
      .count
  end

  def last_cooked_date
    @last_cooked_date ||= DayRecipe
      .joins(:day)
      .where(days: { user_id: current_user.id }, recipe_id: recipe.id)
      .maximum("days.date")
  end
end
