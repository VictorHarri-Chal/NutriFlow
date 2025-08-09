class CreateDayFoodGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :day_food_groups do |t|
      t.string :name, null: false
      t.bigint :user_id, null: false
      t.timestamps
    end

    add_index :day_food_groups, :user_id
    add_foreign_key :day_food_groups, :users

    # Ajouter une colonne day_food_group_id à la table day_foods
    add_column :day_foods, :day_food_group_id, :bigint
    add_index :day_foods, :day_food_group_id
    add_foreign_key :day_foods, :day_food_groups
  end
end
