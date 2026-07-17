class AddTensionProfileToExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :exercises, :tension_profile, :string
  end
end
