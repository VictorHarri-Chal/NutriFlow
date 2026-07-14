class CreateBodyMeasurements < ActiveRecord::Migration[8.0]
  def change
    create_table :body_measurements do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :waist_cm,  precision: 5, scale: 2
      t.decimal :hips_cm,   precision: 5, scale: 2
      t.decimal :chest_cm,  precision: 5, scale: 2
      t.decimal :biceps_cm, precision: 5, scale: 2
      t.decimal :thighs_cm, precision: 5, scale: 2
      t.decimal :calves_cm, precision: 5, scale: 2
      t.decimal :neck_cm,   precision: 5, scale: 2

      t.timestamps
    end

    add_index :body_measurements, [:user_id, :date], unique: true
  end
end
