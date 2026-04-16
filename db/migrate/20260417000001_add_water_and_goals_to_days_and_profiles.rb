class AddWaterAndGoalsToDaysAndProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :days, :water_ml, :integer, default: 0, null: false
    add_column :profiles, :water_goal_ml, :integer, default: 2000, null: false
    add_column :profiles, :goal_weight, :decimal, precision: 5, scale: 2
  end
end
