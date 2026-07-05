# frozen_string_literal: true

class RecipeSidebarComponent < ApplicationComponent
  MICRONUTRIENT_ORDER = %w[calcium iron magnesium potassium sodium zinc cholesterol
                            vitamin_c vitamin_d vitamin_b12 vitamin_a vitamin_b9 epa dha].freeze
  MICRONUTRIENT_UNITS = {
    "calcium" => "mg", "iron" => "mg", "magnesium" => "mg", "potassium" => "mg",
    "sodium" => "mg", "zinc" => "mg", "cholesterol" => "mg",
    "vitamin_c" => "mg", "vitamin_d" => "µg", "vitamin_b12" => "µg",
    "vitamin_a" => "µg", "vitamin_b9" => "µg", "epa" => "g", "dha" => "g"
  }.freeze

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
    MICRONUTRIENT_ORDER.filter_map do |key|
      value = micronutrients[key]
      next unless value.present? && value != 0
      { key: key, value: value, unit: MICRONUTRIENT_UNITS[key] }
    end
  end

  def allergens
    @allergens ||= recipe.aggregated_allergens
  end

  def traces
    @traces ||= recipe.aggregated_traces
  end

  attr_reader :times_cooked, :last_cooked_date
end
