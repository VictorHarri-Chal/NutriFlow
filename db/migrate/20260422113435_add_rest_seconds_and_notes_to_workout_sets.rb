class AddRestSecondsAndNotesToWorkoutSets < ActiveRecord::Migration[8.0]
  def change
    add_column :workout_sets, :rest_seconds, :integer
    add_column :workout_sets, :notes, :text
  end
end
