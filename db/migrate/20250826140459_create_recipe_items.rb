class CreateRecipeItems < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_items do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :food, null: false, foreign_key: true
      t.decimal :quantity, null: false, default: 100.0

      t.timestamps
    end

    add_index :recipe_items, [:recipe_id, :food_id]
  end
end
