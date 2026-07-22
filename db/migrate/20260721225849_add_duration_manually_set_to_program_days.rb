class AddDurationManuallySetToProgramDays < ActiveRecord::Migration[8.0]
  def change
    add_column :program_days, :duration_manually_set, :boolean, null: false, default: false
  end
end
