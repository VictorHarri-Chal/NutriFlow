class AddFieldsToExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :exercises, :description, :text
    add_column :exercises, :difficulty, :string
    add_column :exercises, :category, :string
  end
end
