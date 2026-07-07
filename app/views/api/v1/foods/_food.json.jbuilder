json.id               food.id
json.name             food.name
json.brand            food.brand
json.calories         food.calories
json.proteins         food.proteins
json.carbs            food.carbs
json.fats             food.fats
json.sugars           food.sugars
json.fiber            food.fiber
json.saturated_fat    food.saturated_fat
json.salt             food.salt
json.category         food.category
json.favorite         food.favorite
json.in_pantry        food.in_pantry
json.source           food.source
json.off_id           food.off_id
json.nutriscore_grade food.nutriscore_grade
json.nova_group       food.nova_group
json.ecoscore_grade   food.ecoscore_grade
json.allergens        food.allergens
json.traces           food.traces
json.additives        food.additives
json.labels           food.labels
json.ingredients_text food.ingredients_text
json.micronutrients   food.micronutrients

json.food_labels food.food_labels do |fl|
  json.id    fl.id
  json.name  fl.name
  json.color fl.color
end
