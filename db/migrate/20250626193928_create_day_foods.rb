class CreateDayFoods < ActiveRecord::Migration[8.0]
  def change
    create_table :day_foods do |t|
      t.references :day, null: false, foreign_key: true
      t.references :food, null: false, foreign_key: true
      t.decimal :quantity, null: false, default: 1.0

      t.timestamps
    end

    add_index :day_foods, [:day_id, :food_id]
  end
end
