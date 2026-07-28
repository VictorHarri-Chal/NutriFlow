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
