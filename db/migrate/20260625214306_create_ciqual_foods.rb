class CreateCiqualFoods < ActiveRecord::Migration[8.0]
  def change
    create_table :ciqual_foods do |t|
      t.string  :alim_code,  null: false
      t.string  :name,       null: false
      t.string  :food_group
      t.decimal :calories,   precision: 6, scale: 2, default: 0
      t.decimal :proteins,   precision: 6, scale: 2, default: 0
      t.decimal :carbs,      precision: 6, scale: 2, default: 0
      t.decimal :fats,       precision: 6, scale: 2, default: 0
      t.decimal :sugars,     precision: 6, scale: 2, default: 0
      t.timestamps
    end

    add_index :ciqual_foods, :alim_code, unique: true
    add_index :ciqual_foods, :name
  end
end
