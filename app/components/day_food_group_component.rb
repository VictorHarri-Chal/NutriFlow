class DayFoodGroupComponent < ApplicationComponent
  def initialize(day_food_group: nil, day_foods:)
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

  def item_count_text
    count = day_foods.count
    if count == 1
      "1 élément"
    else
      "#{count} éléments"
    end
  end

  def group_title
    if day_food_group
      day_food_group.name
    else
      "Éléments sans groupe"
    end
  end

  def group_bg_class
    if day_food_group
      "from-blue-50 to-indigo-50"
    else
      "from-gray-50 to-gray-100"
    end
  end

  def badge_bg_class
    if day_food_group
      "bg-blue-100 text-blue-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def is_recipe?(item)
    item.is_a?(DayRecipe)
  end

  def edit_path(item)
    if is_recipe?(item)
      edit_day_day_recipe_path(item.day, item)
    else
      edit_day_day_food_path(item.day, item)
    end
  end

  def delete_path(item)
    if is_recipe?(item)
      day_day_recipe_path(item.day, item)
    else
      day_day_food_path(item.day, item)
    end
  end

  def delete_confirm_message(item)
    if is_recipe?(item)
      "Es-tu sûr de vouloir supprimer cette recette ?"
    else
      "Es-tu sûr de vouloir supprimer cet aliment ?"
    end
  end
end
