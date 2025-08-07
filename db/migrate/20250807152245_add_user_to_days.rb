class AddUserToDays < ActiveRecord::Migration[8.0]
  def change
    add_reference :days, :user, null: false, foreign_key: true
  end
end
