class CreateDayRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :day_recipes do |t|
      t.references :day, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.references :day_food_group, null: true, foreign_key: true
      t.decimal :quantity, precision: 8, scale: 2
      t.boolean :use_recipe_quantity, default: false

      t.timestamps
    end
  end
end
