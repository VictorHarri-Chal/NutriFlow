json.data @shopping_lists do |sl|
  json.id              sl.id
  json.name            sl.name
  json.unchecked_count sl.shopping_list_items.count { |item| !item.checked }
end
