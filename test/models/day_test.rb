require "test_helper"

class DayTest < ActiveSupport::TestCase
  def assert_cached_matches_live(day)
    day.reload
    live = day.send(:compute_live_totals)
    %i[calories proteins carbs fats sugars].each do |k|
      assert_in_delta live[k], day.public_send("total_#{k}"), 0.01, "cached_#{k} drifted from live"
    end
  end

  test "cached totals populate on day_food create and match live" do
    user = create_user
    day  = create_day(user: user)
    food = create_food(user: user, calories: 200, proteins: 10)
    create_day_food(day: day, food: food, quantity: 250) # 200 * 2.5 = 500 kcal

    assert_in_delta 500.0, day.reload.total_calories, 0.01
    assert_cached_matches_live(day)
  end

  test "removing a day_food refreshes the cached totals" do
    user = create_user
    day  = create_day(user: user)
    f1   = create_food(user: user, calories: 100)
    f2   = create_food(user: user, calories: 300)
    df1  = create_day_food(day: day, food: f1, quantity: 100) # 100
    create_day_food(day: day, food: f2, quantity: 100)        # 300
    assert_in_delta 400.0, day.reload.total_calories, 0.01

    df1.destroy
    assert_in_delta 300.0, day.reload.total_calories, 0.01
    assert_cached_matches_live(day)
  end

  test "changing a day_food quantity refreshes the cached totals" do
    user = create_user
    day  = create_day(user: user)
    food = create_food(user: user, calories: 100)
    df   = create_day_food(day: day, food: food, quantity: 100) # 100
    assert_in_delta 100.0, day.reload.total_calories, 0.01

    df.update!(quantity: 250)
    assert_in_delta 250.0, day.reload.total_calories, 0.01
    assert_cached_matches_live(day)
  end

  test "logging a recipe contributes its snapshot totals to the day" do
    user   = create_user
    day    = create_day(user: user)
    food   = create_food(user: user, calories: 100)
    recipe = create_recipe(user: user, items: [{ food: food, quantity: 200 }]) # 200 kcal whole
    create_day_recipe(day: day, recipe: recipe, log_use_whole: true)

    assert_in_delta 200.0, day.reload.total_calories, 0.01
    assert_cached_matches_live(day)
  end

  test "editing a logged recipe's item quantity refreshes the day cached total" do
    user   = create_user
    day    = create_day(user: user)
    food   = create_food(user: user, calories: 100)
    recipe = create_recipe(user: user, items: [{ food: food, quantity: 100 }]) # 100 kcal whole
    dr     = create_day_recipe(day: day, recipe: recipe, log_use_whole: true)
    assert_in_delta 100.0, day.reload.total_calories, 0.01

    item = dr.day_recipe_items.first
    dr.update!(day_recipe_items_attributes: [{ id: item.id, quantity: item.quantity * 2 }])
    assert_in_delta 200.0, day.reload.total_calories, 0.01
    assert_cached_matches_live(day)
  end

  test "a detached logged recipe (source recipe deleted) still contributes to the cache" do
    user   = create_user
    day    = create_day(user: user)
    food   = create_food(user: user, calories: 100)
    recipe = create_recipe(user: user, items: [{ food: food, quantity: 100 }])
    dr     = create_day_recipe(day: day, recipe: recipe, log_use_whole: true)
    assert_in_delta 100.0, day.reload.total_calories, 0.01

    recipe.destroy # graceful deletion: day_recipe.recipe_id nullified, snapshot survives
    assert dr.reload.detached?
    assert_in_delta 100.0, day.reload.total_calories, 0.01 # frozen snapshot, unchanged
    assert_cached_matches_live(day)
  end

  # The core guarantee of the snapshot model: a later master edit must NOT change
  # an already-logged day (and must NOT trigger a spurious day recompute).
  test "editing a food's macros does NOT change an already-logged day" do
    user = create_user
    day  = create_day(user: user)
    food = create_food(user: user, calories: 100)
    create_day_food(day: day, food: food, quantity: 100) # snapshot frozen at 100 kcal/100g
    assert_in_delta 100.0, day.reload.total_calories, 0.01

    food.update!(calories: 999) # master edit
    assert_in_delta 100.0, day.reload.total_calories, 0.01 # frozen snapshot, unchanged
  end
end
