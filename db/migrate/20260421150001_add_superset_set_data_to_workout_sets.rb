class AddSupersetSetDataToWorkoutSets < ActiveRecord::Migration[8.0]
  def change
    add_column :workout_sets, :superset_weight_kg, :decimal, precision: 6, scale: 2
    add_column :workout_sets, :superset_reps, :integer
  end
end
