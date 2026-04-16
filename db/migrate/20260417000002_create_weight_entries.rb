class CreateWeightEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :weight_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.date    :date,      null: false
      t.decimal :weight_kg, null: false, precision: 5, scale: 2
      t.timestamps
    end

    add_index :weight_entries, [:user_id, :date], unique: true
  end
end
