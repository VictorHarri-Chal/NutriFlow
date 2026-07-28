class ReorderDaysUserDateIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # Dominant access pattern is user_id equality + date range/order (statistics,
  # calendar). A (user_id, date) index serves the equality then the range in one
  # descent and makes ORDER BY date free; it also covers the user_id FK lookup,
  # making the two previous indexes redundant.
  def up
    add_index :days, [:user_id, :date], unique: true,
              name: "index_days_on_user_id_and_date", algorithm: :concurrently
    remove_index :days, name: "index_days_on_date_and_user_id", algorithm: :concurrently
    remove_index :days, name: "index_days_on_user_id", algorithm: :concurrently
  end

  def down
    add_index :days, [:date, :user_id], unique: true,
              name: "index_days_on_date_and_user_id", algorithm: :concurrently
    add_index :days, :user_id, name: "index_days_on_user_id", algorithm: :concurrently
    remove_index :days, name: "index_days_on_user_id_and_date", algorithm: :concurrently
  end
end
