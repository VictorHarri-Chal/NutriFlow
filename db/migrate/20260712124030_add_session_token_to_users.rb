class AddSessionTokenToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :session_token, :string
    User.find_each { |user| user.update_column(:session_token, SecureRandom.hex(20)) }
    change_column_null :users, :session_token, false
  end

  def down
    remove_column :users, :session_token
  end
end
