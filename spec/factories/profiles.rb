FactoryBot.define do
  factory :profile do
    transient do
      owner { create(:user) }
      age { 30 }
    end

    name { "Test User" }
    date_of_birth { Date.current - age.years }
    weight { 80.0 }
    height { 180.0 }
    goal_weight { 75.0 }
    gender { "male" }
    goal { "weight_loss" }
    job_activity_level { "light_activity" }
    default_daily_steps { 8000 }
    water_goal_ml { 2500 }

    skip_create

    initialize_with { owner.profile }

    after(:build) do |profile, evaluator|
      profile.assign_attributes(
        name: evaluator.name,
        date_of_birth: evaluator.date_of_birth,
        weight: evaluator.weight,
        height: evaluator.height,
        goal_weight: evaluator.goal_weight,
        gender: evaluator.gender,
        goal: evaluator.goal,
        job_activity_level: evaluator.job_activity_level,
        default_daily_steps: evaluator.default_daily_steps,
        water_goal_ml: evaluator.water_goal_ml
      )
    end

    after(:create, &:save!)
  end
end
