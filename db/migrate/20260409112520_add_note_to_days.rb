class AddNoteToDays < ActiveRecord::Migration[8.0]
  def change
    add_column :days, :note, :text
  end
end
