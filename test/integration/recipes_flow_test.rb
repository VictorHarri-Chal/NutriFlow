require "test_helper"

class RecipesFlowTest < ActionDispatch::IntegrationTest
  # The duplicate action builds items on a fresh recipe then saves it, so the
  # after_save recompute must populate the copy's denormalized totals.
  test "duplicating a recipe carries its denormalized totals" do
    user   = create_user
    food   = create_food(user: user, calories: 150)
    recipe = create_recipe(user: user, name: "Original", items: [{ food: food, quantity: 200 }]) # 300 kcal
    sign_in user

    assert_difference -> { user.recipes.count }, 1 do
      post duplicate_recipe_path(recipe)
    end

    copy = user.recipes.order(:created_at).last
    assert_not_equal recipe.id, copy.id
    assert_in_delta 300.0, copy.total_calories, 0.01
  end
end
