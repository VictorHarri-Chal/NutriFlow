json.data @food_labels do |fl|
  json.id    fl.id
  json.name  fl.name
  json.color fl.color
end

json.available_colors FoodLabel::COLORS
