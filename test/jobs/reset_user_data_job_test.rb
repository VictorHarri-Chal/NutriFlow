require "test_helper"

class ResetUserDataJobTest < ActiveJob::TestCase
  test "wipes the user's owned data and recreates a fresh profile" do
    user = create_user
    food = create_food(user: user)
    day  = create_day(user: user)
    create_day_food(day: day, food: food, quantity: 100)

    ResetUserDataJob.perform_now(user)

    user.reload
    assert_equal 0, user.foods.count
    assert_equal 0, user.days.count
    assert user.profile.present?, "a fresh profile is recreated after a reset"
  end

  test "is safe to run twice (converges to one profile, no data)" do
    user = create_user
    create_food(user: user)

    ResetUserDataJob.perform_now(user)
    ResetUserDataJob.perform_now(user)

    user.reload
    assert_equal 0, user.foods.count
    assert_equal 1, Profile.where(user_id: user.id).count, "exactly one profile survives a double reset"
  end
end
