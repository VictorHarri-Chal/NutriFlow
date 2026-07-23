class AddTimeZoneToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :time_zone, :string, default: "Europe/Paris", null: false
  end
end
