class CreateExerciseFavorites < ActiveRecord::Migration[8.0]
  def change
    create_table :exercise_favorites do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.timestamps
    end

    add_index :exercise_favorites, [:user_id, :exercise_id], unique: true
  end
end
