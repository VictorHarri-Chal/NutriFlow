class CreateCardioBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :cardio_blocks do |t|
      t.references :cardio_session, null: false, foreign_key: true
      t.string :machine
      t.integer :duration_minutes
      t.decimal :speed_kmh, precision: 4, scale: 1
      t.integer :incline_percent
      t.integer :resistance_level
      t.decimal :distance_km, precision: 5, scale: 2
      t.integer :calories_burned
      t.integer :position

      t.timestamps
    end
  end
end
