class CreateProgramExerciseSets < ActiveRecord::Migration[8.0]
  def change
    create_table :program_exercise_sets do |t|
      t.references :program_exercise, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.integer :reps_target, null: false
      t.decimal :weight_target, precision: 6, scale: 2
      t.integer :rpe
      t.string :set_types, array: true, default: [], null: false

      t.timestamps
    end

    add_index :program_exercise_sets, [:program_exercise_id, :position]
  end
end
