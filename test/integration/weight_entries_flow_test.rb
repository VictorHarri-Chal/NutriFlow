require "test_helper"

# Guards the QUERY-3 refactor: @entries / @measurements are now materialized to
# arrays and every chart/stat is computed in Ruby (pagy_array + select instead
# of relation .where/.reverse_order). A broken conversion would 500 here.
class WeightEntriesFlowTest < ActionDispatch::IntegrationTest
  test "poids tab renders with materialized entries" do
    user = create_user
    create_weight_entry(user: user, date: 40.days.ago.to_date, weight_kg: 80.0)
    create_weight_entry(user: user, date: 5.days.ago.to_date,  weight_kg: 78.0)
    sign_in user

    get weight_entries_path(tab: "poids")
    assert_response :success
  end

  test "poids tab renders with no entries" do
    sign_in create_user
    get weight_entries_path(tab: "poids")
    assert_response :success
  end

  test "mesures tab renders with materialized measurements" do
    user = create_user
    user.body_measurements.create!(date: 3.days.ago.to_date, waist_cm: 85)
    sign_in user

    get weight_entries_path(tab: "mesures")
    assert_response :success
  end
end
