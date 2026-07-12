class AddUniqueIndexToDayFoodGroups < ActiveRecord::Migration[8.0]
  def change
    remove_index :day_food_groups, :user_id
    add_index :day_food_groups, [:name, :user_id], unique: true
  end
end
