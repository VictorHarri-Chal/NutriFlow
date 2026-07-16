class AddCustomizedToDayRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :day_recipes, :customized, :boolean, default: false, null: false
  end
end
