class ReplaceActivityLevelWithJobNeat < ActiveRecord::Migration[8.0]
  def up
    # Map existing activity_level to job_activity_level before removing
    activity_to_job = {
      "sedentary"         => "desk_job",
      "lightly_active"    => "light_activity",
      "moderately_active" => "light_activity",
      "very_active"       => "standing_job",
      "extremely_active"  => "physical_job"
    }
    activity_to_job_steps = {
      "sedentary"         => 4_000,
      "lightly_active"    => 6_000,
      "moderately_active" => 8_000,
      "very_active"       => 10_000,
      "extremely_active"  => 12_000
    }

    add_column :profiles, :job_activity_level, :string, default: "light_activity", null: false
    add_column :profiles, :default_daily_steps, :integer, default: 6_000, null: false

    execute <<~SQL
      UPDATE profiles SET
        job_activity_level = CASE activity_level
          WHEN 'sedentary'         THEN 'desk_job'
          WHEN 'lightly_active'    THEN 'light_activity'
          WHEN 'moderately_active' THEN 'light_activity'
          WHEN 'very_active'       THEN 'standing_job'
          WHEN 'extremely_active'  THEN 'physical_job'
          ELSE 'light_activity'
        END,
        default_daily_steps = CASE activity_level
          WHEN 'sedentary'         THEN 4000
          WHEN 'lightly_active'    THEN 6000
          WHEN 'moderately_active' THEN 8000
          WHEN 'very_active'       THEN 10000
          WHEN 'extremely_active'  THEN 12000
          ELSE 6000
        END
    SQL

    remove_column :profiles, :activity_level
    add_column :days, :steps, :integer
  end

  def down
    add_column :profiles, :activity_level, :string
    remove_column :profiles, :job_activity_level
    remove_column :profiles, :default_daily_steps
    remove_column :days, :steps
  end
end
