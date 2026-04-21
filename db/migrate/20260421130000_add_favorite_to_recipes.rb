class AddFavoriteToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :favorite, :boolean, default: false, null: false
  end
end
