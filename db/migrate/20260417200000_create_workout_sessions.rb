class CreateWorkoutSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_sessions do |t|
      t.references :day, null: false, foreign_key: true
      t.integer :duration_minutes
      t.integer :rpe
      t.text :notes
      t.integer :calories_burned
      t.timestamps
    end
  end
end
