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
json.bmr                      profile.bmr
json.base_tdee                profile.base_tdee
json.daily_calorie_target     profile.calories_needed_for_goal
json.daily_protein_goal       profile.daily_protein_goal
json.daily_fats_goal          profile.daily_fats_goal
json.daily_carbs_goal         profile.daily_carbs_goal
json.computed_water_goal_ml   profile.computed_water_goal_ml
