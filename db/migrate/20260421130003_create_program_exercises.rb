class CreateProgramExercises < ActiveRecord::Migration[8.0]
  def change
    create_table :program_exercises do |t|
      t.references :program_day, null: false, foreign_key: true
      t.references :exercise,    null: false, foreign_key: true
      t.integer :sets,         default: 3, null: false
      t.integer :reps_target,  default: 10, null: false
      t.decimal :weight_target, precision: 6, scale: 2
      t.integer :rest_seconds
      t.integer :position,     default: 0, null: false
      t.text    :notes
      t.timestamps
    end

    add_index :program_exercises, [:program_day_id, :position]
  end
end
