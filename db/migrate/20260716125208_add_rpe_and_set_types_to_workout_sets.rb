class AddRpeAndSetTypesToWorkoutSets < ActiveRecord::Migration[8.0]
  def change
    add_column :workout_sets, :rpe, :integer
    add_column :workout_sets, :set_types, :string, array: true, null: false, default: ["working"]
    remove_column :workout_sessions, :rpe, :integer
  end
end
