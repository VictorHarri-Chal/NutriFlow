json.id           @recipe.id
json.name         @recipe.name
json.instructions @recipe.instructions
json.favorite     @recipe.favorite

json.total_calories     @recipe.total_calories
json.total_proteins     @recipe.total_proteins
json.total_carbs        @recipe.total_carbs
json.total_fats         @recipe.total_fats
json.total_sugars       @recipe.total_sugars
json.total_weight       @recipe.total_weight
json.total_fiber        @recipe.total_fiber
json.total_saturated_fat @recipe.total_saturated_fat
json.total_salt         @recipe.total_salt

json.recipe_items @recipe.recipe_items.includes(:food) do |item|
  json.id             item.id
  json.food_id        item.food_id
  json.food_name      item.food.name
  json.quantity       item.quantity
  json.unit           item.unit
  json.total_calories item.total_calories
  json.total_proteins item.total_proteins
  json.total_carbs    item.total_carbs
  json.total_fats     item.total_fats
end

all_ratings = @recipe.recipe_ratings.to_a
user_rating = all_ratings.find { |r| r.user_id == current_user.id }
if user_rating
  json.user_rating do
    json.id      user_rating.id
    json.rating  user_rating.rating
    json.comment user_rating.comment
  end
else
  json.user_rating nil
end

json.ratings_average all_ratings.any? ? (all_ratings.sum(&:rating).to_f / all_ratings.size).round(1) : nil
