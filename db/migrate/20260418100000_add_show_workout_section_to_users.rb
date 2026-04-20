class AddShowWorkoutSectionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :show_workout_section, :boolean, default: true, null: false
  end
end
