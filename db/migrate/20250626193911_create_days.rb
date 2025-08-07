class CreateDays < ActiveRecord::Migration[8.0]
  def change
    create_table :days do |t|
      t.date :date, null: false

      t.timestamps
    end

    add_index :days, :date, unique: true
  end
end
