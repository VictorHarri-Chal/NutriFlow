class AddFavoriteToFoods < ActiveRecord::Migration[8.0]
  def change
    add_column :foods, :favorite, :boolean, default: false, null: false
  end
end
