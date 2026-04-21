class AddDurationAndNotesToProgramDays < ActiveRecord::Migration[8.0]
  def change
    add_column :program_days, :duration_minutes, :integer
    add_column :program_days, :notes, :text
  end
end
