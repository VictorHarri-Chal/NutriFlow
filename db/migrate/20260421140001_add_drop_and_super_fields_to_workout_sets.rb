class AddDropAndSuperFieldsToWorkoutSets < ActiveRecord::Migration[8.0]
  def change
    add_column :workout_sets, :drop_weight_kg, :decimal, precision: 6, scale: 2
    add_column :workout_sets, :drop_reps, :integer
    add_reference :workout_sets, :superset_exercise, foreign_key: { to_table: :exercises }, null: true
  end
end
