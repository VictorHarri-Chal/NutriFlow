require "test_helper"

# CACHE-1b: the statistics endpoint is a conditional GET. The per-tab etag folds
# in a data stamp (MAX days.updated_at for nutrition), so an unchanged tab returns
# 304 (no re-aggregation) and any logged change invalidates it.
class StatisticsCacheTest < ActionDispatch::IntegrationTest
  test "nutrition tab: 304 when unchanged, 200 after a logged change" do
    user = create_user
    day  = create_day(user: user)
    food = create_food(user: user, calories: 100)
    create_day_food(day: day, food: food, quantity: 100)
    sign_in user

    get statistics_path(tab: "nutrition")
    assert_response :success
    etag = response.headers["ETag"]
    assert etag.present?, "expected an ETag on the stats response"

    # Same data → not modified
    get statistics_path(tab: "nutrition"), headers: { "If-None-Match" => etag }
    assert_response :not_modified

    # A new log bumps the day's updated_at → stamp (and etag) change → 200
    travel 1.second do
      create_day_food(day: day, food: food, quantity: 50)
    end
    get statistics_path(tab: "nutrition"), headers: { "If-None-Match" => etag }
    assert_response :success
  end

  test "nutrition tab: removing a logged food invalidates the cache" do
    user = create_user
    day  = create_day(user: user)
    food = create_food(user: user, calories: 100)
    create_day_food(day: day, food: food, quantity: 100)
    df2  = create_day_food(day: day, food: food, quantity: 50)
    sign_in user

    get statistics_path(tab: "nutrition")
    etag = response.headers["ETag"]
    get statistics_path(tab: "nutrition"), headers: { "If-None-Match" => etag }
    assert_response :not_modified

    travel(1.second) { df2.destroy } # recompute bumps days.updated_at
    get statistics_path(tab: "nutrition"), headers: { "If-None-Match" => etag }
    assert_response :success
  end

  # Guards review findings 1 & 2: a child edit (set) and a session deletion must
  # both invalidate the training stamp, which a plain MAX(session.updated_at) missed.
  test "training tab: invalidated by a set edit and by a session deletion" do
    user    = create_user
    day     = create_day(user: user)
    exercise = create_exercise(name: "Bench")
    session = create_workout_session(day: day, exercise: exercise)
    sign_in user

    get statistics_path(tab: "training")
    assert_response :success
    etag1 = response.headers["ETag"]
    get statistics_path(tab: "training"), headers: { "If-None-Match" => etag1 }
    assert_response :not_modified

    # Finding 1: editing a child set (which does not touch its session) invalidates
    travel(1.second) { session.workout_sets.first.update!(reps: 12) }
    get statistics_path(tab: "training"), headers: { "If-None-Match" => etag1 }
    assert_response :success
    etag2 = response.headers["ETag"]

    # Finding 2: deleting a session (a plain MAX would be blind) invalidates
    session.destroy
    get statistics_path(tab: "training"), headers: { "If-None-Match" => etag2 }
    assert_response :success
  end
end
