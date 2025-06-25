class CreateFoods < ActiveRecord::Migration[8.0]
  def change
    create_table :foods do |t|
      t.string :name, null: false
      t.string :brand
      t.decimal :fats, null: false
      t.decimal :carbs, null: false
      t.decimal :sugars, null: false
      t.decimal :proteins, null: false
      t.decimal :calories, null: false

      t.timestamps
    end

    add_index :foods, :name
    add_index :foods, :brand
  end
end
