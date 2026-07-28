class NullifyNutritionLogMasterFks < ActiveRecord::Migration[8.0]
  def up
    change_column_null :day_foods,        :food_id,   true
    change_column_null :day_recipe_items, :food_id,   true
    change_column_null :day_recipes,      :recipe_id, true

    remove_foreign_key :day_foods,        :foods
    add_foreign_key    :day_foods,        :foods,   on_delete: :nullify

    remove_foreign_key :day_recipe_items, :foods
    add_foreign_key    :day_recipe_items, :foods,   on_delete: :nullify

    remove_foreign_key :day_recipes,      :recipes
    add_foreign_key    :day_recipes,      :recipes, on_delete: :nullify
  end

  def down
    remove_foreign_key :day_foods,        :foods
    add_foreign_key    :day_foods,        :foods
    remove_foreign_key :day_recipe_items, :foods
    add_foreign_key    :day_recipe_items, :foods
    remove_foreign_key :day_recipes,      :recipes
    add_foreign_key    :day_recipes,      :recipes
    change_column_null :day_foods,        :food_id,   false
    change_column_null :day_recipe_items, :food_id,   false
    change_column_null :day_recipes,      :recipe_id, false
  end
end
