class AddFastingFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :fasting_disclaimer_acknowledged_at, :datetime
    add_column :users, :show_fasting_tracking, :boolean, default: true, null: false
  end
end
