class AddArchivedAtToShoppingLists < ActiveRecord::Migration[8.0]
  def change
    add_column :shopping_lists, :archived_at, :datetime
    add_index  :shopping_lists, [:user_id, :archived_at]
  end
end
