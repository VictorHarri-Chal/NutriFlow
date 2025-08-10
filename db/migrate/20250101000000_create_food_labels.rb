class CreateFoodLabels < ActiveRecord::Migration[7.1]
  def change
    create_table :food_labels do |t|
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :food_labels, [:name, :user_id], unique: true
  end
end
