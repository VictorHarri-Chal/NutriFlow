class AddPerformanceIndexesToFoods < ActiveRecord::Migration[8.0]
  def change
    # Composite indexes for common Ransack/scope filter combinations (user_id + filter column)
    add_index :foods, [:user_id, :favorite],  name: "index_foods_on_user_id_and_favorite"
    add_index :foods, [:user_id, :in_pantry], name: "index_foods_on_user_id_and_in_pantry"
    add_index :foods, [:user_id, :category],  name: "index_foods_on_user_id_and_category"

    # DB-level uniqueness: the model validates uniqueness scoped to user_id but concurrent
    # requests can bypass model validations — this constraint enforces it at the DB level.
    add_index :foods, [:user_id, :name], unique: true, name: "index_foods_on_user_id_and_name_unique"
  end
end
