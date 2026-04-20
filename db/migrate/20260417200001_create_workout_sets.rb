class CreateWorkoutSets < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_sets do |t|
      t.references :workout_session, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.decimal :weight_kg, precision: 6, scale: 2
      t.integer :reps
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    add_index :workout_sets, [:workout_session_id, :position]
  end
end
