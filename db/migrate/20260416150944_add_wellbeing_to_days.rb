class AddWellbeingToDays < ActiveRecord::Migration[8.0]
  def change
    add_column :days, :energy_level, :integer
    add_column :days, :mood, :integer
    add_column :days, :sleep_quality, :integer
  end
end
