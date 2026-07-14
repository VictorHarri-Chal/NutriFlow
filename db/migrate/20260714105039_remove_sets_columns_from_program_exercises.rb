class RemoveSetsColumnsFromProgramExercises < ActiveRecord::Migration[8.0]
  def change
    remove_column :program_exercises, :sets, :integer, default: 3, null: false
    remove_column :program_exercises, :reps_target, :integer, default: 10, null: false
    remove_column :program_exercises, :weight_target, :decimal, precision: 6, scale: 2
  end
end
