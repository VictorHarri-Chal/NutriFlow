class AddMissingIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :day_foods,    :food_id,     name: "index_day_foods_on_food_id"     unless index_exists?(:day_foods,    :food_id)
    add_index :workout_sets, :exercise_id, name: "index_workout_sets_on_exercise_id" unless index_exists?(:workout_sets, :exercise_id)
  end
end
