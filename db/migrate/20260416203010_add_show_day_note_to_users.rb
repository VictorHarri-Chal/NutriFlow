class AddShowDayNoteToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :show_day_note, :boolean, default: true, null: false
  end
end
