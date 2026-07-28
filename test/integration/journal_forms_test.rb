require "test_helper"

# Guards QUERY-1: the journal add-forms load @foods with a column-limited
# .select and serialize exactly those columns to JSON. A missing column (or a
# view reading an unselected attribute) would raise MissingAttributeError here.
class JournalFormsTest < ActionDispatch::IntegrationTest
  test "day_foods#new renders with the column-limited foods payload" do
    user = create_user
    day  = user.days.create!(date: Date.today)
    create_food(user: user, name: "Poulet")
    sign_in user

    get new_day_day_food_path(day)
    assert_response :success
  end

  test "day_recipes#new renders with the column-limited foods payload" do
    user = create_user
    day  = user.days.create!(date: Date.today)
    food = create_food(user: user, name: "Riz")
    create_recipe(user: user, name: "Bol", items: [{ food: food, quantity: 100 }])
    sign_in user

    get new_day_day_recipe_path(day)
    assert_response :success
  end
end
