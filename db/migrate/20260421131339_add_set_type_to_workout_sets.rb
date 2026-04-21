class AddSetTypeToWorkoutSets < ActiveRecord::Migration[8.0]
  def change
    add_column :workout_sets, :set_type, :string, default: "normal", null: false
  end
end
