json.id              @shopping_list.id
json.name            @shopping_list.name
json.unchecked_count @shopping_list.unchecked_count

json.items @shopping_list.shopping_list_items.order(:position, :created_at) do |item|
  json.id       item.id
  json.food_id  item.food_id
  json.name     item.name
  json.quantity item.quantity
  json.checked  item.checked
  json.category item.category
  json.position item.position
end
