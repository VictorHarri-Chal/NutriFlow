class CreateRecipeRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_ratings do |t|
      t.integer :rating, null: false
      t.text :comment
      t.references :recipe, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :recipe_ratings, [:recipe_id, :user_id], unique: true
    add_check_constraint :recipe_ratings, "rating >= 1 AND rating <= 5", name: "check_rating_range"
  end
end
