day = @day
profile = current_user.profile

json.id            day.id
json.date          day.date
json.note          day.note
json.energy_level  day.energy_level
json.mood          day.mood
json.sleep_quality day.sleep_quality
json.water_ml      day.water_ml
json.steps         day.steps
json.effective_steps day.effective_steps(profile)

day_with_foods = current_user.days.includes(
  day_foods:   [:food, :day_food_group],
  day_recipes: [:day_food_group, { recipe: { recipe_items: :food } }],
  workout_sessions: { workout_sets: :exercise },
  cardio_sessions:  { cardio_blocks: {} }
).find(day.id)

json.day_foods day_with_foods.day_foods do |df|
  json.id               df.id
  json.food_id          df.food_id
  json.food_name        df.food.name
  json.quantity         df.quantity
  json.day_food_group_id df.day_food_group_id
  json.total_calories   df.total_calories
  json.total_proteins   df.total_proteins
  json.total_carbs      df.total_carbs
  json.total_fats       df.total_fats
  json.total_sugars     df.total_sugars
end

json.day_recipes day_with_foods.day_recipes do |dr|
  json.id                  dr.id
  json.recipe_id           dr.recipe_id
  json.recipe_name         dr.recipe.name
  json.quantity            dr.quantity
  json.use_recipe_quantity dr.use_recipe_quantity
  json.day_food_group_id   dr.day_food_group_id
  json.total_calories      dr.total_calories
  json.total_proteins      dr.total_proteins
  json.total_carbs         dr.total_carbs
  json.total_fats          dr.total_fats
  json.total_sugars        dr.total_sugars
end

all_entries = day_with_foods.day_foods.to_a + day_with_foods.day_recipes.to_a
json.totals do
  json.calories all_entries.sum { |e| e.total_calories.to_f }.round
  json.proteins all_entries.sum { |e| e.total_proteins.to_f }.round(1)
  json.carbs    all_entries.sum { |e| e.total_carbs.to_f }.round(1)
  json.fats     all_entries.sum { |e| e.total_fats.to_f }.round(1)
  json.sugars   all_entries.sum { |e| e.total_sugars.to_f }.round(1)
end

json.workout_sessions day_with_foods.workout_sessions do |ws|
  json.id               ws.id
  json.duration_minutes ws.duration_minutes
  json.rpe              ws.rpe
  json.notes            ws.notes
  json.calories_burned  ws.calories_burned
  json.sets ws.workout_sets do |s|
    json.id            s.id
    json.exercise_id   s.exercise_id
    json.exercise_name s.exercise&.name
    json.weight_kg     s.weight_kg
    json.reps          s.reps
    json.position      s.position
    json.rest_seconds  s.rest_seconds
    json.is_pr         s.is_pr
  end
end

json.cardio_sessions day_with_foods.cardio_sessions do |cs|
  json.id             cs.id
  json.notes          cs.notes
  json.total_duration cs.total_duration
  json.total_calories cs.total_calories
  json.blocks cs.cardio_blocks.order(:position) do |b|
    json.id               b.id
    json.machine          b.machine
    json.duration_minutes b.duration_minutes
    json.speed_kmh        b.speed_kmh
    json.incline_percent  b.incline_percent
    json.resistance_level b.resistance_level
    json.distance_km      b.distance_km
    json.calories_burned  b.calories_burned
    json.position         b.position
  end
end
