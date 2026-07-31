require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  test "total_* aggregate the gram-scaled macros of every recipe item" do
    user  = create_user
    food1 = create_food(user: user, calories: 200, proteins: 10, carbs: 20, fats: 5, sugars: 2)
    food2 = create_food(user: user, calories: 100, proteins: 8,  carbs: 4,  fats: 2, sugars: 1)

    recipe = create_recipe(user: user, items: [
      { food: food1, quantity: 250 }, # gram_factor 2.5
      { food: food2, quantity: 150 }  # gram_factor 1.5
    ])

    # food1: 200*2.5=500 kcal / food2: 100*1.5=150 kcal
    assert_in_delta 650.0, recipe.total_calories, 0.1
    assert_in_delta 37.0,  recipe.total_proteins, 0.1 # 10*2.5 + 8*1.5
    assert_in_delta 400.0, recipe.total_weight,   0.1 # 250 + 150
  end

  # ── Denormalized totals (phase 2a) ──────────────────────────────────────
  # Each test proves the stored columns equal the live computation across every
  # mutation path that can make them stale.

  def assert_columns_match_live(recipe)
    recipe.reload
    live = recipe.send(:compute_live_totals, recipe.recipe_items.includes(:food).to_a)
    %i[calories proteins carbs fats sugars weight fiber saturated_fat salt].each do |k|
      assert_in_delta live[k], recipe.public_send("total_#{k}"), 0.01, "total_#{k} drifted from live"
    end
  end

  test "totals are denormalized on create and match the live computation" do
    user = create_user
    food = create_food(user: user, calories: 200, proteins: 10, carbs: 20, fats: 5, sugars: 2)
    recipe = create_recipe(user: user, items: [{ food: food, quantity: 250 }])

    assert_in_delta 500.0, recipe.reload.total_calories, 0.01 # 200 * 2.5
    assert_columns_match_live(recipe)
  end

  test "adding an ingredient refreshes the totals" do
    user = create_user
    f1 = create_food(user: user, calories: 100)
    recipe = create_recipe(user: user, items: [{ food: f1, quantity: 100 }])
    assert_in_delta 100.0, recipe.reload.total_calories, 0.01

    f2 = create_food(user: user, calories: 300)
    recipe.update!(recipe_items_attributes: [{ food_id: f2.id, quantity: 100 }])
    assert_in_delta 400.0, recipe.reload.total_calories, 0.01
    assert_columns_match_live(recipe)
  end

  test "removing an ingredient refreshes the totals" do
    user = create_user
    f1 = create_food(user: user, calories: 100)
    f2 = create_food(user: user, calories: 300)
    recipe = create_recipe(user: user, items: [{ food: f1, quantity: 100 }, { food: f2, quantity: 100 }])
    assert_in_delta 400.0, recipe.reload.total_calories, 0.01

    item = recipe.recipe_items.find_by(food_id: f2.id)
    recipe.update!(recipe_items_attributes: [{ id: item.id, _destroy: true }])
    assert_in_delta 100.0, recipe.reload.total_calories, 0.01
    assert_columns_match_live(recipe)
  end

  test "changing an ingredient quantity refreshes the totals" do
    user = create_user
    food = create_food(user: user, calories: 100)
    recipe = create_recipe(user: user, items: [{ food: food, quantity: 100 }])
    item = recipe.recipe_items.first

    recipe.update!(recipe_items_attributes: [{ id: item.id, quantity: 250 }])
    assert_in_delta 250.0, recipe.reload.total_calories, 0.01
    assert_columns_match_live(recipe)
  end

  test "editing a food's macros cascades to every recipe that uses it" do
    user = create_user
    food = create_food(user: user, calories: 100)
    recipe = create_recipe(user: user, items: [{ food: food, quantity: 100 }])
    assert_in_delta 100.0, recipe.reload.total_calories, 0.01

    food.update!(calories: 250)
    assert_in_delta 250.0, recipe.reload.total_calories, 0.01
    assert_columns_match_live(recipe)
  end

  test "totals scale correctly for a kg-unit ingredient (no decimal overflow)" do
    user = create_user
    food = create_food(user: user, calories: 100)
    # 2 kg = 2000 g → gram_factor 20 → 2000 kcal, well within decimal(14,2)
    recipe = create_recipe(user: user, items: [{ food: food, quantity: 2, unit: "kg" }])

    assert_in_delta 2000.0, recipe.reload.total_calories, 0.01
    assert_in_delta 2000.0, recipe.total_weight, 0.01
    assert_columns_match_live(recipe)
  end

  test "totals aggregate fiber, saturated_fat and salt across multiple items" do
    user = create_user
    f1 = create_food(user: user, fiber: 3, saturated_fat: 1.5, salt: 0.4)
    f2 = create_food(user: user, fiber: 2, saturated_fat: 0.5, salt: 0.1)
    recipe = create_recipe(user: user, items: [{ food: f1, quantity: 100 }, { food: f2, quantity: 200 }])

    recipe.reload
    assert_in_delta 7.0, recipe.total_fiber,         0.01 # 3*1 + 2*2
    assert_in_delta 2.5, recipe.total_saturated_fat, 0.01 # 1.5*1 + 0.5*2
    assert_in_delta 0.6, recipe.total_salt,          0.01 # 0.4*1 + 0.1*2
    assert_columns_match_live(recipe)
  end

  test "editing a non-macro food attribute does NOT need a recompute but stays consistent" do
    user = create_user
    food = create_food(user: user, calories: 100, name: "Avoine")
    recipe = create_recipe(user: user, items: [{ food: food, quantity: 100 }])

    food.update!(name: "Flocons d'avoine") # name is not a macro
    assert_columns_match_live(recipe) # totals unchanged, still correct
  end

  test "uniqueness of name is scoped per user and case-insensitive" do
    user  = create_user
    other = create_user
    food  = create_food(user: user)
    create_recipe(user: user, name: "Poulet Curry", items: [{ food: food, quantity: 100 }])

    dup = user.recipes.build(name: "poulet curry")
    dup.recipe_items.build(food: food, quantity: 100)
    assert_not dup.valid?
    assert_includes dup.errors.attribute_names, :name

    # same name is fine for a different user
    other_food = create_food(user: other)
    assert create_recipe(user: other, name: "Poulet Curry", items: [{ food: other_food, quantity: 100 }]).persisted?
  end
end
