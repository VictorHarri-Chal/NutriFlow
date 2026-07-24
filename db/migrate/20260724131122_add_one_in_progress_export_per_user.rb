class AddOneInProgressExportPerUser < ActiveRecord::Migration[8.0]
  def change
    # At most one in-flight (pending/processing) export per user, enforced at the
    # DB level so two concurrent POSTs can't both slip past the controller guard
    # and enqueue duplicate heavy jobs.
    add_index :data_exports, :user_id, unique: true,
              where: "status IN ('pending', 'processing')",
              name: "index_data_exports_on_one_in_progress_per_user"
  end
end
