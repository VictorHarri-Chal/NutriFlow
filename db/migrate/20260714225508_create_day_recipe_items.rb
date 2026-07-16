class CreateDayRecipeItems < ActiveRecord::Migration[8.0]
  def change
    create_table :day_recipe_items do |t|
      t.references :day_recipe, null: false, foreign_key: true
      t.references :food, null: false, foreign_key: true
      t.decimal :quantity, default: "100.0", null: false
      t.string :unit, default: "g", null: false

      t.timestamps
    end
  end
end
