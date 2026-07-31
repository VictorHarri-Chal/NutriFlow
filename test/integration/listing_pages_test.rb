require "test_helper"

class ListingPagesTest < ActionDispatch::IntegrationTest
  # CACHE-1a wraps the exercise card body in a fragment cache; IMG-1 preloads
  # variant records. A broken cache/end balance or a bad includes path would
  # 500 here instead of rendering.
  test "exercises index renders the (cached) card body" do
    create_exercise(name: "Developpe couche", body_part: "chest", equipment: "barbell")
    sign_in create_user

    get exercises_path
    assert_response :success
    assert_match "Developpe couche", response.body
  end

  # RENDER-1 switches the recipe grid to RecipeCardComponent.with_collection.
  # A wrong collection param name would raise on render.
  test "recipes index renders recipe cards via with_collection" do
    user = create_user
    food = create_food(user: user, name: "Avoine")
    create_recipe(user: user, name: "Porridge", items: [{ food: food, quantity: 200 }])
    sign_in user

    get recipes_path
    assert_response :success
    assert_match "Porridge", response.body
  end
end
