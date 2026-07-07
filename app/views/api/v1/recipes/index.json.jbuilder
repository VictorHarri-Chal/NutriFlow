json.data @recipes do |recipe|
  json.id       recipe.id
  json.name     recipe.name
  json.favorite recipe.favorite
  json.total_calories   recipe.total_calories
  json.total_proteins   recipe.total_proteins
  json.total_carbs      recipe.total_carbs
  json.total_fats       recipe.total_fats
  json.total_sugars     recipe.total_sugars
  json.total_weight     recipe.total_weight
end

json.meta do
  json.current_page @pagy.page
  json.total_pages  @pagy.pages
  json.total_count  @pagy.count
end
