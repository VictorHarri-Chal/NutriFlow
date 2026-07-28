class DropLegacyDayRecipeColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :day_recipes, :customized,          :boolean, default: false, null: false
    remove_column :day_recipes, :use_recipe_quantity, :boolean, default: false
    remove_column :day_recipes, :quantity,            :decimal, precision: 8, scale: 2
  end
end
