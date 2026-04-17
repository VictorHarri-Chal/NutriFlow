class AddGifStatusToExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :exercises, :gif_status, :string
  end
end
