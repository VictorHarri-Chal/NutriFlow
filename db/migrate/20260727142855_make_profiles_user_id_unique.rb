class MakeProfilesUserIdUnique < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # Profile is a has_one on User; the FK index should enforce uniqueness at the
  # DB level too (mirrors the new `validates :user_id, uniqueness: true`).
  def up
    remove_index :profiles, name: "index_profiles_on_user_id", algorithm: :concurrently
    add_index :profiles, :user_id, unique: true,
              name: "index_profiles_on_user_id", algorithm: :concurrently
  end

  def down
    remove_index :profiles, name: "index_profiles_on_user_id", algorithm: :concurrently
    add_index :profiles, :user_id,
              name: "index_profiles_on_user_id", algorithm: :concurrently
  end
end
