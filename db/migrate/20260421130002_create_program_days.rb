class CreateProgramDays < ActiveRecord::Migration[8.0]
  def change
    create_table :program_days do |t|
      t.references :workout_program, null: false, foreign_key: true
      t.integer :day_of_week, null: false   # 0 = Mon … 6 = Sun
      t.string  :name                       # nil = rest day
      t.timestamps
    end

    add_index :program_days, [:workout_program_id, :day_of_week], unique: true
  end
end
