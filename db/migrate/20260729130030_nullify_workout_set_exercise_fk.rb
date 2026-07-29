class NullifyWorkoutSetExerciseFk < ActiveRecord::Migration[8.0]
  def up
    change_column_null :workout_sets, :exercise_id, true
    remove_foreign_key :workout_sets, :exercises
    add_foreign_key    :workout_sets, :exercises, on_delete: :nullify
  end

  def down
    remove_foreign_key :workout_sets, :exercises
    add_foreign_key    :workout_sets, :exercises
    change_column_null :workout_sets, :exercise_id, false
  end
end
