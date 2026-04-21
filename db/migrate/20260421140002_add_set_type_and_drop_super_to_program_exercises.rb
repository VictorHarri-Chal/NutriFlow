class AddSetTypeAndDropSuperToProgramExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :program_exercises, :set_type, :string, default: "normal", null: false
    add_column :program_exercises, :drop_weight_target, :decimal, precision: 6, scale: 2
    add_column :program_exercises, :drop_reps_target, :integer
    add_reference :program_exercises, :superset_exercise, foreign_key: { to_table: :exercises }, null: true
  end
end
