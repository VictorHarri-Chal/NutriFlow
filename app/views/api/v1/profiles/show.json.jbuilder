profile = current_user.profile

json.id                   profile.id
json.name                 profile.name
json.weight               profile.weight
json.height               profile.height
json.age                  profile.age
json.gender               profile.gender
json.job_activity_level   profile.job_activity_level
json.goal                 profile.goal
json.goal_weight          profile.goal_weight
json.water_goal_ml        profile.water_goal_ml
json.default_daily_steps  profile.default_daily_steps

# Computed (read-only)
json.expenditure do
  json.bmr           profile.bmr
  json.job_neat      Profile::JOB_NEAT_KCAL[profile.job_activity_level&.to_sym] || Profile::JOB_NEAT_KCAL[:light_activity]
  json.steps_kcal    profile.neat_from_steps(profile.default_daily_steps || 6_000)
  json.steps_count   profile.default_daily_steps
  json.workout_kcal  0
  json.tdee          profile.base_tdee
  json.goal_delta    (profile.calories_needed_for_goal && profile.base_tdee) ? profile.calories_needed_for_goal - profile.base_tdee : nil
end

json.goals do
  json.calories  profile.calories_needed_for_goal
  json.proteins  profile.daily_protein_goal
  json.fats      profile.daily_fats_goal
  json.carbs     profile.daily_carbs_goal
end
