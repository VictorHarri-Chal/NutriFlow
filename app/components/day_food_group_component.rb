class DayFoodGroupComponent < ApplicationComponent
  def initialize(day_food_group: nil, day_foods:, day:)
    @day_food_group = day_food_group
    @day_foods      = day_foods
    @day            = day
  end

  private

  attr_reader :day_food_group, :day_foods, :day

  def group_totals
    {
      calories: day_foods.sum(&:total_calories),
      proteins: day_foods.sum(&:total_proteins),
      carbs:    day_foods.sum(&:total_carbs),
      fats:     day_foods.sum(&:total_fats),
      sugars:   day_foods.sum(&:total_sugars)
    }
  end

  def group_title
    day_food_group ? day_food_group.name : I18n.t("views.components.day_food_group.ungrouped_title")
  end

  def accent_border_class
    day_food_group ? "border-l-brand" : "border-l-surface-border/50"
  end

  def storage_key
    key = day_food_group ? "group_#{day_food_group.id}" : "ungrouped"
    "collapsible:calendar:#{key}"
  end

  def add_food_path
    new_day_day_food_path(day, day_food: { day_food_group_id: day_food_group&.id }.compact)
  end

  def add_recipe_path
    new_day_day_recipe_path(day, day_recipe: { day_food_group_id: day_food_group&.id }.compact)
  end

  def is_recipe?(item)
    item.is_a?(DayRecipe)
  end

  def edit_path(item)
    is_recipe?(item) ? edit_day_recipe_path(item) : edit_day_food_path(item)
  end

  def delete_path(item)
    is_recipe?(item) ? day_recipe_path(item) : day_food_path(item)
  end

  def delete_confirm_message(item)
    key = is_recipe?(item) ? "delete_recipe_confirm" : "delete_food_confirm"
    I18n.t("views.components.day_food_group.#{key}")
  end
end
