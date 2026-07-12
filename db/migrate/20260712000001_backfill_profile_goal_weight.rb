class BackfillProfileGoalWeight < ActiveRecord::Migration[8.0]
  def up
    Profile.where(goal_weight: nil).where.not(weight: nil).find_each do |profile|
      profile.update_columns(goal_weight: profile.weight, goal: "maintenance")
    end
  end

  def down
    # Irreversible: we can't distinguish backfilled values from explicit ones.
  end
end
