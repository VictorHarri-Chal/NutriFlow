class AddPreferenceTogglesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :show_water_tracking,  :boolean, default: true, null: false
    add_column :users, :show_tdee_breakdown,   :boolean, default: true, null: false
    add_column :users, :show_weight_tracking,  :boolean, default: true, null: false
  end
end
