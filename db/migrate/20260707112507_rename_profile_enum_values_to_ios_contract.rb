class RenameProfileEnumValuesToIosContract < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE profiles SET goal = 'maintain' WHERE goal = 'maintenance'"
    execute "UPDATE profiles SET job_activity_level = 'sedentary' WHERE job_activity_level = 'desk_job'"
  end

  def down
    execute "UPDATE profiles SET goal = 'maintenance' WHERE goal = 'maintain'"
    execute "UPDATE profiles SET job_activity_level = 'desk_job' WHERE job_activity_level = 'sedentary'"
  end
end
