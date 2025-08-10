class CreateFoodLabelsFoods < ActiveRecord::Migration[7.1]
  def change
    create_table :food_labels_foods, id: false do |t|
      t.references :food_label, null: false, foreign_key: true
      t.references :food, null: false, foreign_key: true
    end

    add_index :food_labels_foods, [:food_label_id, :food_id], unique: true
  end
end
