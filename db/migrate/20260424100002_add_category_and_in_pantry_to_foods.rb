class AddCategoryAndInPantryToFoods < ActiveRecord::Migration[8.0]
  def change
    add_column :foods, :category,   :string
    add_column :foods, :in_pantry,  :boolean, null: false, default: true
  end
end
