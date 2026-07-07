json.data @foods do |food|
  json.partial! "api/v1/foods/food", food: food
end

json.meta do
  json.current_page @pagy.page
  json.total_pages  @pagy.pages
  json.total_count  @pagy.count
end
