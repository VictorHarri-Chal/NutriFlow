require "test_helper"

class ExerciseTest < ActiveSupport::TestCase
  test "body_parts returns sorted distinct global values, excluding custom exercises (QUERY-2)" do
    create_exercise(body_part: "chest", equipment: "barbell")
    create_exercise(body_part: "back",  equipment: "dumbbell")
    create_exercise(body_part: "chest", equipment: "barbell") # duplicate collapses
    create_exercise(body_part: "neck",  equipment: "machine", custom_user: create_user) # not global

    assert_equal %w[back chest], Exercise.body_parts
  end

  test "equipments returns sorted distinct global values (QUERY-2)" do
    create_exercise(body_part: "chest", equipment: "barbell")
    create_exercise(body_part: "back",  equipment: "dumbbell")
    create_exercise(body_part: "legs",  equipment: "barbell")

    assert_equal %w[barbell dumbbell], Exercise.equipments
  end

  test "body_parts is served from cache on repeat calls (QUERY-2)" do
    create_exercise(body_part: "chest")
    # test env uses :null_store; swap in a real store to exercise the cache path
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    begin
      Exercise.body_parts # warms the cache (1 query)
      assert_no_queries { assert_equal %w[chest], Exercise.body_parts }
    ensure
      Rails.cache = original_cache
    end
  end
end
