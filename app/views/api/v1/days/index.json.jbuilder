json.data @days do |day|
  json.id    day.id
  json.date  day.date
  json.water_ml day.water_ml
  json.steps    day.steps
end
