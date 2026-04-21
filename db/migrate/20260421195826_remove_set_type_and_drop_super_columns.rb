class RemoveSetTypeAndDropSuperColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :workout_sets, :set_type
    remove_column :workout_sets, :drop_weight_kg
    remove_column :workout_sets, :drop_reps
    remove_reference :workout_sets, :superset_exercise, foreign_key: { to_table: :exercises }
    remove_column :workout_sets, :superset_weight_kg
    remove_column :workout_sets, :superset_reps

    remove_column :program_exercises, :set_type
    remove_column :program_exercises, :drop_weight_target
    remove_column :program_exercises, :drop_reps_target
    remove_reference :program_exercises, :superset_exercise, foreign_key: { to_table: :exercises }
  end
end
