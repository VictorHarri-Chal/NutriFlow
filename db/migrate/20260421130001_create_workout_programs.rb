class CreateWorkoutPrograms < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_programs do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name,       null: false
      t.string  :split_type, null: false, default: "custom"
      t.boolean :is_active,  null: false, default: false
      t.timestamps
    end

    add_index :workout_programs, [:user_id, :is_active]
  end
end
