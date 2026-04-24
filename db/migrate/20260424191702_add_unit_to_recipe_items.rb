class AddUnitToRecipeItems < ActiveRecord::Migration[8.0]
  def change
    add_column :recipe_items, :unit, :string, null: false, default: "g"
  end
end
