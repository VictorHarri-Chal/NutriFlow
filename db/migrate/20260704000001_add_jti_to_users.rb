class AddJtiToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :jti, :string, null: false, default: ""
    # Backfill before adding unique index
    User.find_each { |u| u.update_column(:jti, SecureRandom.uuid) }
    add_index :users, :jti, unique: true
  end

  def down
    remove_index :users, :jti
    remove_column :users, :jti
  end
end
