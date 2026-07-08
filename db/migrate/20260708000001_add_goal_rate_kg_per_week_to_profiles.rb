class AddGoalRateKgPerWeekToProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :profiles, :goal_rate_kg_per_week, :decimal, precision: 4, scale: 2, default: 0.0, null: false
  end
end
