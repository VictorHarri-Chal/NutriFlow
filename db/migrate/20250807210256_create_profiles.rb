class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.decimal :weight
      t.decimal :height
      t.integer :age
      t.string :gender
      t.string :activity_level
      t.string :goal

      t.timestamps
    end
  end
end
