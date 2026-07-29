class AddIdentitySnapshotToWorkoutSets < ActiveRecord::Migration[8.0]
  def change
    add_column :workout_sets, :exercise_name, :string
    add_column :workout_sets, :body_part,     :string
  end
end
