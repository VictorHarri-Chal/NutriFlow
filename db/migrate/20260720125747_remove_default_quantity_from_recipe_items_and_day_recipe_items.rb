class RemoveDefaultQuantityFromRecipeItemsAndDayRecipeItems < ActiveRecord::Migration[8.0]
  def change
    change_column_default :recipe_items, :quantity, from: "100.0", to: nil
    change_column_default :day_recipe_items, :quantity, from: "100.0", to: nil
  end
end
