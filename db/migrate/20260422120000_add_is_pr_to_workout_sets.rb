class AddIsPrToWorkoutSets < ActiveRecord::Migration[8.0]
  def change
    add_column :workout_sets, :is_pr, :boolean, default: false, null: false
  end
end
