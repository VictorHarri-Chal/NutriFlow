class AddSnapshotsToNutritionLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :day_foods,        :food_name,     :string
    add_column :day_foods,        :food_snapshot, :jsonb
    add_column :day_recipe_items, :food_name,     :string
    add_column :day_recipe_items, :food_snapshot, :jsonb
    add_column :day_recipes,      :recipe_name,   :string
  end
end
