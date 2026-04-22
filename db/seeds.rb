# db/seeds.rb — NutriFlow comprehensive seed
# Run with: bin/rails db:seed

puts "Seeding NutriFlow…"

# ─────────────────────────────────────────────────────────────────────────────
# USER + PROFILE
# ─────────────────────────────────────────────────────────────────────────────
user = User.find_or_create_by!(email: ENV.fetch("SEED_EMAIL", "victorharrichal@yahoo.com")) do |u|
  u.password              = "password123"
  u.password_confirmation = "password123"
end

profile = user.profile || user.build_profile
profile.update!(
  name:                "Victor",
  weight:              80,
  height:              178,
  age:                 26,
  gender:              :male,
  goal:                :muscle_gain,
  job_activity_level:  :light_activity,
  water_goal_ml:       2500,
  goal_weight:         85,
  default_daily_steps: 8_000
)

# ─────────────────────────────────────────────────────────────────────────────
# CLEAR PREVIOUS DATA (safe order for FK constraints)
# ─────────────────────────────────────────────────────────────────────────────
user.days.destroy_all
user.workout_programs.destroy_all
user.exercise_favorites.destroy_all
user.recipes.destroy_all
user.foods.destroy_all
user.day_food_groups.destroy_all
user.food_labels.destroy_all

# ─────────────────────────────────────────────────────────────────────────────
# FOOD LABELS
# ─────────────────────────────────────────────────────────────────────────────
lbl_proteine  = FoodLabel.create!(name: "Protéine",  user: user)
lbl_glucide   = FoodLabel.create!(name: "Glucide",   user: user)
lbl_lipide    = FoodLabel.create!(name: "Lipide",    user: user)
lbl_condiment = FoodLabel.create!(name: "Condiment", user: user)
lbl_fibre     = FoodLabel.create!(name: "Fibre",     user: user)

# ─────────────────────────────────────────────────────────────────────────────
# MEAL GROUPS
# ─────────────────────────────────────────────────────────────────────────────
grp_matin     = DayFoodGroup.create!(name: "Petit-Déjeuner", user: user)
grp_dejeuner  = DayFoodGroup.create!(name: "Déjeuner",       user: user)
grp_collation = DayFoodGroup.create!(name: "Collation",      user: user)
grp_diner     = DayFoodGroup.create!(name: "Dîner",          user: user)

# ─────────────────────────────────────────────────────────────────────────────
# FOODS  (valeurs / 100g : kcal, prot, lip, glu, suc)
# ─────────────────────────────────────────────────────────────────────────────
foods_data = [
  # ── Protéines ──────────────────────────────────────────────────────────────
  ["Skyr nature",              57,   8.8,  0.2,  4.0,  4.0, [lbl_proteine]],
  ["Oeuf entier",             155,  13.0, 11.0,  0.7,  0.7, [lbl_proteine]],
  ["Blanc d'oeuf",             52,  11.0,  0.2,  0.7,  0.7, [lbl_proteine]],
  ["Poulet (blanc)",          110,  23.0,  2.5,  0.0,  0.0, [lbl_proteine]],
  ["Viande hachée 5%",        130,  20.0,  5.0,  0.0,  0.0, [lbl_proteine]],
  ["Thon en boite (eau)",     113,  26.0,  1.0,  0.0,  0.0, [lbl_proteine]],
  ["Saumon fumé",             172,  25.0,  7.5,  0.0,  0.0, [lbl_proteine]],
  ["Sardines en boite",       185,  22.0, 11.0,  0.0,  0.0, [lbl_proteine]],
  ["Cottage cheese",           98,  11.0,  4.5,  3.0,  3.0, [lbl_proteine]],
  ["Feta",                    283,  15.0, 23.0,  0.0,  0.0, [lbl_proteine]],
  ["Fromage blanc 0%",         45,   8.0,  0.1,  3.5,  3.5, [lbl_proteine]],
  ["Petits suisses",           87,   9.0,  4.5,  5.0,  4.5, [lbl_proteine]],
  ["Graine de chia",          486,  17.0, 31.0, 42.0,  0.5, [lbl_proteine, lbl_lipide, lbl_fibre]],
  ["Lentilles cuites",        116,   9.0,  0.4, 20.0,  1.5, [lbl_proteine, lbl_fibre]],
  ["Pois chiches cuits",      164,   8.9,  2.6, 27.0,  4.8, [lbl_proteine, lbl_fibre]],
  ["Beurre de cacahuète",     597,  25.0, 50.0, 20.0,  9.0, [lbl_proteine, lbl_lipide]],

  # ── Féculents & céréales ───────────────────────────────────────────────────
  ["Avoine (flocons)",        370,  13.0,  7.0, 60.0,  1.0, [lbl_glucide, lbl_fibre]],
  ["Riz complet (cru)",       350,   7.5,  2.5, 72.0,  0.5, [lbl_glucide]],
  ["Pâte complète (crue)",    350,  13.0,  2.5, 68.0,  3.0, [lbl_glucide, lbl_fibre]],
  ["Riz basmati (cru)",       358,   7.0,  0.8, 80.0,  0.3, [lbl_glucide]],
  ["Patate douce",             86,   1.6,  0.1, 20.0,  4.0, [lbl_glucide]],
  ["Pain de seigle",          259,   9.0,  3.5, 48.0,  3.0, [lbl_glucide, lbl_fibre]],
  ["Quinoa (cuit)",           120,   4.4,  1.9, 22.0,  1.0, [lbl_glucide, lbl_proteine]],

  # ── Fruits ────────────────────────────────────────────────────────────────
  ["Banane",                   89,   1.1,  0.3, 23.0, 12.0, [lbl_glucide]],
  ["Pomme",                    52,   0.3,  0.2, 13.0, 10.0, [lbl_glucide]],
  ["Poire",                    55,   0.4,  0.2, 13.0, 10.0, [lbl_glucide]],
  ["Myrtilles surgelées",      57,   0.7,  0.3, 14.0, 10.0, [lbl_glucide]],
  ["Fruits rouges surgelés",   45,   1.0,  0.3, 11.0,  8.0, [lbl_glucide]],
  ["Fraises",                  33,   0.7,  0.3,  8.0,  5.5, [lbl_glucide]],

  # ── Légumes ───────────────────────────────────────────────────────────────
  ["Tomate",                   18,   0.9,  0.2,  3.5,  3.0, [lbl_glucide]],
  ["Concombre",                15,   0.6,  0.1,  3.6,  2.0, [lbl_glucide]],
  ["Brocoli surgelé",          35,   3.0,  0.4,  6.0,  2.0, [lbl_glucide, lbl_fibre]],
  ["Épinards surgelés",        23,   2.9,  0.4,  3.8,  0.4, [lbl_glucide, lbl_fibre]],
  ["Courgette",                17,   1.2,  0.3,  3.0,  2.5, [lbl_glucide]],
  ["Poivron rouge",            31,   1.0,  0.3,  7.0,  5.0, [lbl_glucide]],
  ["Champignons de paris",     22,   3.1,  0.3,  3.0,  2.0, [lbl_glucide, lbl_fibre]],
  ["Oignon",                   40,   1.1,  0.1,  9.0,  5.0, [lbl_glucide]],
  ["Avocat",                  160,   2.0, 15.0,  9.0,  0.5, [lbl_lipide]],
  ["Maïs en conserve",         76,   2.8,  1.2, 16.0,  5.0, [lbl_glucide]],
  ["Carottes",                 41,   0.9,  0.2,  9.6,  5.0, [lbl_glucide, lbl_fibre]],

  # ── Lipides & oléagineux ──────────────────────────────────────────────────
  ["Amandes",                 579,  21.0, 50.0, 22.0,  4.0, [lbl_lipide]],
  ["Noix",                    654,  15.0, 65.0,  7.0,  2.0, [lbl_lipide]],
  ["Noix de cajou",           553,  18.0, 44.0, 33.0,  6.0, [lbl_lipide]],
  ["Chocolat noir 85%",       566,  12.5, 47.0, 29.0, 10.0, [lbl_lipide]],
  ["Huile d'olive",           900,   0.0,100.0,  0.0,  0.0, [lbl_lipide]],

  # ── Condiments ────────────────────────────────────────────────────────────
  ["Miel",                    304,   0.3,  0.0, 82.0, 82.0, [lbl_condiment]],
  ["Sauce soja",               60,   6.0,  0.0,  8.0,  3.0, [lbl_condiment]],
  ["Vinaigre balsamique",      88,   0.5,  0.0, 17.0, 14.0, [lbl_condiment]],
  ["Cornichons",               22,   1.2,  0.2,  3.5,  1.0, [lbl_condiment]],
  ["Moutarde",                 66,   4.4,  3.3,  5.0,  1.5, [lbl_condiment]],
  ["Ail",                     149,   6.4,  0.5, 33.0,  1.0, [lbl_condiment]],
  ["Paprika",                 282,  14.0, 13.0, 54.0, 10.0, [lbl_condiment]],
  ["Cumin",                   375,  18.0, 22.0, 44.0,  2.0, [lbl_condiment]],
  ["Curcuma",                 354,   8.0, 10.0, 65.0,  3.0, [lbl_condiment]],
  ["Cannelle",                247,   4.0,  1.5, 55.0,  2.0, [lbl_condiment]],
  ["Herbes de Provence",      265,  10.0,  6.0, 42.0,  5.0, [lbl_condiment]],
  ["Persil frais",             36,   3.0,  0.8,  6.0,  1.0, [lbl_condiment]],
]

food_map = {}
foods_data.each do |name, kcal, prot, lip, glu, suc, labels|
  f = Food.create!(name: name, calories: kcal, proteins: prot,
                   fats: lip, carbs: glu, sugars: suc, user: user)
  f.food_labels << labels
  food_map[name] = f
end
puts "  ✓ #{user.foods.count} aliments"

# ─────────────────────────────────────────────────────────────────────────────
# RECIPES
# ─────────────────────────────────────────────────────────────────────────────
def build_recipe(user, name, ingredients)
  r = Recipe.new(name: name, user: user)
  ingredients.each { |food, qty| r.recipe_items.build(food: food, quantity: qty) }
  r.save!
  r
end

f = food_map  # shorthand

r_overnight_oats = build_recipe(user, "Overnight Oats Myrtilles", [
  [f["Avoine (flocons)"],     80],
  [f["Skyr nature"],         150],
  [f["Myrtilles surgelées"], 100],
  [f["Graine de chia"],       15],
  [f["Miel"],                 15],
  [f["Cannelle"],              2],
])

r_smoothie = build_recipe(user, "Smoothie Protéiné Fruits Rouges", [
  [f["Skyr nature"],              200],
  [f["Fruits rouges surgelés"],   120],
  [f["Banane"],                    80],
  [f["Avoine (flocons)"],          30],
  [f["Miel"],                      10],
])

r_omelette = build_recipe(user, "Omelette Épinards Champignons", [
  [f["Oeuf entier"],           200],
  [f["Blanc d'oeuf"],          100],
  [f["Épinards surgelés"],     100],
  [f["Champignons de paris"],   80],
  [f["Huile d'olive"],          10],
])

r_bol_poulet = build_recipe(user, "Bol Poulet Riz Brocoli", [
  [f["Poulet (blanc)"],      200],
  [f["Riz complet (cru)"],    80],
  [f["Brocoli surgelé"],     150],
  [f["Sauce soja"],           20],
  [f["Huile d'olive"],        10],
])

r_quinoa_bowl = build_recipe(user, "Bowl Quinoa Poulet Poivron", [
  [f["Quinoa (cuit)"],     180],
  [f["Poulet (blanc)"],    160],
  [f["Poivron rouge"],     100],
  [f["Épinards surgelés"],  80],
  [f["Sauce soja"],         15],
  [f["Huile d'olive"],      10],
])

r_bolognaise = build_recipe(user, "Pâtes Bolognaise Maison", [
  [f["Pâte complète (crue)"],  120],
  [f["Viande hachée 5%"],      150],
  [f["Tomate"],                200],
  [f["Oignon"],                 80],
  [f["Ail"],                     8],
  [f["Huile d'olive"],          10],
  [f["Herbes de Provence"],      3],
])

r_curry_lentilles = build_recipe(user, "Curry de Lentilles", [
  [f["Lentilles cuites"],  200],
  [f["Tomate"],            150],
  [f["Oignon"],             80],
  [f["Curcuma"],             5],
  [f["Cumin"],               5],
  [f["Ail"],                 5],
  [f["Huile d'olive"],      15],
])

r_salade_grecque = build_recipe(user, "Salade Grecque", [
  [f["Concombre"],          200],
  [f["Tomate"],             150],
  [f["Feta"],                80],
  [f["Avocat"],              80],
  [f["Vinaigre balsamique"], 20],
  [f["Huile d'olive"],       10],
])

r_salade_thon = build_recipe(user, "Salade Thon Maïs", [
  [f["Thon en boite (eau)"], 150],
  [f["Concombre"],           100],
  [f["Maïs en conserve"],     80],
  [f["Cornichons"],           40],
  [f["Moutarde"],             15],
  [f["Sauce soja"],           10],
])

r_patate_saumon = build_recipe(user, "Patate Douce & Saumon Fumé", [
  [f["Patate douce"],      250],
  [f["Saumon fumé"],       100],
  [f["Fromage blanc 0%"],   80],
  [f["Poivron rouge"],      80],
  [f["Huile d'olive"],       8],
])

puts "  ✓ #{user.recipes.count} recettes"

# ─────────────────────────────────────────────────────────────────────────────
# EXERCISE FAVORITES
# ─────────────────────────────────────────────────────────────────────────────
%w[0025 0027 0024 0091 0023 0056 0294 0472 0088 0739 0015 0047].each do |eid|
  ex = Exercise.find_by(exercise_id: eid)
  ExerciseFavorite.find_or_create_by!(user: user, exercise: ex) if ex
end
puts "  ✓ #{user.exercise_favorites.count} exercices favoris"

# ─────────────────────────────────────────────────────────────────────────────
# WORKOUT PROGRAMS
# ─────────────────────────────────────────────────────────────────────────────

# Helper: attach program_exercises to a ProgramDay
def seed_program_day(day, name_str, duration, exercises)
  day.update!(name: name_str, duration_minutes: duration)
  exercises.each do |(eid, sets, reps, weight, rest)|
    ex = Exercise.find_by(exercise_id: eid)
    next unless ex
    day.program_exercises.create!(
      exercise: ex, sets: sets, reps_target: reps,
      weight_target: weight, rest_seconds: rest
    )
  end
end

# ── Program 1 : PPL  (actif) ─────────────────────────────────────────────────
ppl = WorkoutProgram.create!(
  user: user, name: "PPL — Push Pull Legs",
  split_type: "ppl", is_active: true
)
pd = ppl.program_days.index_by(&:day_of_week)

seed_program_day(pd[0], "Push A", 60, [
  ["0025", 4,  8,  80.0, 120],   # barbell bench press
  ["0047", 3, 10,  65.0,  90],   # incline bench press
  ["0086", 3, 10,  50.0,  90],   # behind-head military press
  ["0178", 3, 15,  12.5,  60],   # cable lateral raise
  ["0056", 3, 12,  35.0,  75],   # lying triceps extension
])

seed_program_day(pd[1], "Pull A", 65, [
  ["0027", 4,  8,  70.0, 120],   # barbell bent over row
  ["0673", 3, 12,  62.5,  90],   # reverse-grip lat pulldown
  ["0015", 3,  8,   nil,  90],   # parallel close-grip pull-up
  ["0023", 3, 12,  22.5,  60],   # alternate biceps curl
  ["0095", 3, 12,  80.0,  60],   # barbell shrug
])

seed_program_day(pd[2], "Legs", 70, [
  ["0024", 4,  6, 100.0, 150],   # bench front squat
  ["0739", 3, 12, 120.0,  90],   # sled 45° leg press
  ["0054", 3, 10,  45.0,  75],   # barbell lunge
  ["0088", 4, 15,  40.0,  60],   # seated calf raise
  ["0001", 3, 20,   nil,  45],   # 3/4 sit-up
])

pd[3].update!(name: nil)         # Jeudi : repos

seed_program_day(pd[4], "Push B", 60, [
  ["0025", 4,  6,  85.0, 150],   # bench press (force)
  ["0047", 3,  8,  70.0, 120],   # incline (charge)
  ["0086", 4, 12,  47.5,  90],   # OHP endurance
  ["0178", 4, 15,  13.0,  60],   # lateral raise
  ["0056", 3, 15,  30.0,  60],   # triceps extension (pumping)
])

seed_program_day(pd[5], "Pull B", 65, [
  ["0027", 4,  6,  75.0, 150],   # row (force)
  ["0673", 4, 10,  65.0,  90],   # lat pulldown
  ["0015", 3, 10,   nil,  90],   # pull-up
  ["0023", 4, 10,  25.0,  60],   # bicep curl
  ["0095", 3, 15,  80.0,  45],   # shrug
])

pd[6].update!(name: nil)         # Dimanche : repos

# ── Program 2 : Upper / Lower  (inactif) ────────────────────────────────────
ul = WorkoutProgram.create!(
  user: user, name: "Upper / Lower 4j",
  split_type: "upper_lower", is_active: false
)
ud = ul.program_days.index_by(&:day_of_week)

seed_program_day(ud[0], "Upper A", 65, [
  ["0025", 4,  5,  87.5, 180],   # bench press (force)
  ["0027", 4,  5,  77.5, 180],   # bent over row
  ["0091", 3,  8,  57.5, 120],   # seated overhead press
  ["0673", 3, 10,  67.5,  90],   # lat pulldown
  ["0023", 3, 12,  25.0,  60],   # bicep curl
  ["0056", 3, 12,  37.5,  60],   # triceps extension
])

seed_program_day(ud[1], "Lower A", 70, [
  ["0024", 4,  5, 110.0, 180],   # front squat
  ["0739", 3, 10, 130.0, 120],   # leg press
  ["1010", 3,  8,  70.0, 120],   # straight leg deadlift
  ["0054", 3, 12,  50.0,  90],   # lunge
  ["0605", 4, 20,  55.0,  60],   # standing calf raise
])

ud[2].update!(name: nil)         # Mercredi : repos

seed_program_day(ud[3], "Upper B", 65, [
  ["0025", 4,  8,  80.0, 120],
  ["0027", 4,  8,  72.5, 120],
  ["0091", 3, 10,  52.5,  90],
  ["0673", 4, 12,  60.0,  90],
  ["0023", 3, 15,  20.0,  60],
  ["0056", 3, 15,  32.5,  60],
])

seed_program_day(ud[4], "Lower B", 70, [
  ["0024", 4,  8, 100.0, 150],
  ["0739", 4, 12, 120.0,  90],
  ["1010", 3, 10,  65.0,  90],
  ["0054", 3, 10,  45.0,  75],
  ["0605", 3, 25,  50.0,  60],
])

ud[5].update!(name: nil)
ud[6].update!(name: nil)

puts "  ✓ 2 programmes, #{ProgramExercise.joins(program_day: :workout_program).where(workout_programs: { user: user }).count} exercices programmés"

# ─────────────────────────────────────────────────────────────────────────────
# CALENDAR  –  April 14–20 2026  (lundi → dimanche)
# ─────────────────────────────────────────────────────────────────────────────

# Lookup objects we'll reuse
ex = ->(eid) { Exercise.find_by(exercise_id: eid) }

bench      = ex.("0025")
incline    = ex.("0047")
ohp        = ex.("0086")
lat_raise  = ex.("0178")
triceps    = ex.("0056")
row        = ex.("0027")
pulldown   = ex.("0673")
pullup_ex  = ex.("0015")
curl       = ex.("0023")
shrug      = ex.("0095")
squat      = ex.("0024")
leg_press  = ex.("0739")
lunge      = ex.("0054")
calf       = ex.("0088")
situp      = ex.("0001")

# Helper: build a WorkoutSession with its sets in one shot
def seed_session(day, duration:, rpe:, sets_data:)
  session = day.workout_sessions.build(duration_minutes: duration, rpe: rpe)
  sets_data.each_with_index do |(exercise, reps, weight), i|
    session.workout_sets.build(exercise: exercise, reps: reps, weight_kg: weight, position: i)
  end
  session.save!
  session
end

# ── April 14 — Lundi — Push A ────────────────────────────────────────────────
d14 = Day.create!(user: user, date: Date.new(2026, 4, 14),
                  energy_level: 4, mood: 4, sleep_quality: 4,
                  water_ml: 2800, steps: 9_200)

seed_session(d14, duration: 62, rpe: 8, sets_data: [
  [bench,     8, 80.0], [bench,     8, 80.0], [bench,     7, 80.0], [bench,  7, 77.5],
  [incline,  10, 65.0], [incline,  10, 65.0], [incline,   9, 62.5],
  [ohp,      10, 50.0], [ohp,      10, 50.0], [ohp,       9, 47.5],
  [lat_raise,15, 12.5], [lat_raise,15, 12.5], [lat_raise,14, 12.5],
  [triceps,  12, 35.0], [triceps,  12, 35.0], [triceps,  11, 32.5],
])

DayRecipe.create!(day: d14, recipe: r_overnight_oats, use_recipe_quantity: true, day_food_group: grp_matin)
DayRecipe.create!(day: d14, recipe: r_bol_poulet,     use_recipe_quantity: true, day_food_group: grp_dejeuner)
DayFood.create!(day: d14, food: f["Amandes"],           quantity: 40,  day_food_group: grp_collation)
DayFood.create!(day: d14, food: f["Fromage blanc 0%"],  quantity: 200, day_food_group: grp_collation)
DayRecipe.create!(day: d14, recipe: r_bolognaise,       use_recipe_quantity: true, day_food_group: grp_diner)
DayFood.create!(day: d14, food: f["Chocolat noir 85%"], quantity: 30,  day_food_group: grp_diner)

# ── April 15 — Mardi — Pull A ─────────────────────────────────────────────────
d15 = Day.create!(user: user, date: Date.new(2026, 4, 15),
                  energy_level: 3, mood: 4, sleep_quality: 3,
                  water_ml: 2600, steps: 7_800)

seed_session(d15, duration: 66, rpe: 7, sets_data: [
  [row,      8, 70.0], [row,      8, 70.0], [row,      7, 70.0], [row,      7, 67.5],
  [pulldown,12, 62.5], [pulldown,12, 62.5], [pulldown,10, 62.5],
  [pullup_ex, 8, nil], [pullup_ex, 7, nil], [pullup_ex, 6, nil],
  [curl,     12, 22.5], [curl,    12, 22.5], [curl,    11, 22.5],
  [shrug,    12, 80.0], [shrug,   12, 80.0], [shrug,   12, 80.0],
])

DayRecipe.create!(day: d15, recipe: r_smoothie,        use_recipe_quantity: true, day_food_group: grp_matin)
DayFood.create!(  day: d15, food: f["Oeuf entier"],     quantity: 200,             day_food_group: grp_matin)
DayRecipe.create!(day: d15, recipe: r_salade_thon,      use_recipe_quantity: true, day_food_group: grp_dejeuner)
DayFood.create!(  day: d15, food: f["Pain de seigle"],  quantity: 80,              day_food_group: grp_dejeuner)
DayFood.create!(  day: d15, food: f["Noix de cajou"],   quantity: 35,              day_food_group: grp_collation)
DayFood.create!(  day: d15, food: f["Cottage cheese"],  quantity: 200,             day_food_group: grp_collation)
DayRecipe.create!(day: d15, recipe: r_curry_lentilles,  use_recipe_quantity: true, day_food_group: grp_diner)
DayFood.create!(  day: d15, food: f["Patate douce"],    quantity: 200,             day_food_group: grp_diner)

# ── April 16 — Mercredi — Legs ────────────────────────────────────────────────
d16 = Day.create!(user: user, date: Date.new(2026, 4, 16),
                  energy_level: 5, mood: 5, sleep_quality: 5,
                  water_ml: 3000, steps: 11_500)

seed_session(d16, duration: 72, rpe: 9, sets_data: [
  [squat,     6, 100.0], [squat,    6, 100.0], [squat,    5, 102.5], [squat,   5, 105.0],
  [leg_press,12, 120.0], [leg_press,12,125.0], [leg_press,11,125.0],
  [lunge,    10,  45.0], [lunge,   10,  45.0], [lunge,    9,  45.0],
  [calf,     15,  40.0], [calf,    15,  40.0], [calf,    15,  42.5], [calf,   14, 42.5],
  [situp,    20,  nil],  [situp,   20,  nil],  [situp,   18,  nil],
])

DayRecipe.create!(day: d16, recipe: r_overnight_oats,  use_recipe_quantity: true, day_food_group: grp_matin)
DayFood.create!(  day: d16, food: f["Banane"],          quantity: 120,             day_food_group: grp_matin)
DayRecipe.create!(day: d16, recipe: r_quinoa_bowl,      use_recipe_quantity: true, day_food_group: grp_dejeuner)
DayFood.create!(  day: d16, food: f["Amandes"],         quantity: 40,              day_food_group: grp_collation)
DayFood.create!(  day: d16, food: f["Fraises"],         quantity: 150,             day_food_group: grp_collation)
DayRecipe.create!(day: d16, recipe: r_patate_saumon,    use_recipe_quantity: true, day_food_group: grp_diner)
DayFood.create!(  day: d16, food: f["Chocolat noir 85%"], quantity: 40,            day_food_group: grp_diner)

# ── April 17 — Jeudi — Repos ──────────────────────────────────────────────────
d17 = Day.create!(user: user, date: Date.new(2026, 4, 17),
                  energy_level: 3, mood: 3, sleep_quality: 4,
                  water_ml: 2400, steps: 6_500,
                  note: "Journée de récupération, léger déficit calorique volontaire.")

DayRecipe.create!(day: d17, recipe: r_omelette,        use_recipe_quantity: true, day_food_group: grp_matin)
DayFood.create!(  day: d17, food: f["Pain de seigle"], quantity: 60,              day_food_group: grp_matin)
DayRecipe.create!(day: d17, recipe: r_salade_grecque,  use_recipe_quantity: true, day_food_group: grp_dejeuner)
DayFood.create!(  day: d17, food: f["Pois chiches cuits"], quantity: 150,         day_food_group: grp_dejeuner)
DayFood.create!(  day: d17, food: f["Pomme"],          quantity: 150,             day_food_group: grp_collation)
DayFood.create!(  day: d17, food: f["Beurre de cacahuète"], quantity: 30,         day_food_group: grp_collation)
DayRecipe.create!(day: d17, recipe: r_curry_lentilles, use_recipe_quantity: true, day_food_group: grp_diner)

# ── April 18 — Vendredi — Push B ──────────────────────────────────────────────
d18 = Day.create!(user: user, date: Date.new(2026, 4, 18),
                  energy_level: 4, mood: 5, sleep_quality: 4,
                  water_ml: 2700, steps: 8_900)

seed_session(d18, duration: 58, rpe: 8, sets_data: [
  [bench,    6, 85.0], [bench,    6, 85.0], [bench,    5, 87.5], [bench,    5, 87.5],
  [incline,  8, 70.0], [incline,  8, 70.0], [incline,  7, 70.0],
  [ohp,     12, 47.5], [ohp,     12, 47.5], [ohp,     11, 47.5], [ohp,    11, 45.0],
  [lat_raise,15, 13.0], [lat_raise,15,13.0], [lat_raise,14,13.0], [lat_raise,14,12.5],
  [triceps, 15, 30.0], [triceps, 15, 30.0], [triceps, 14, 30.0],
])

DayRecipe.create!(day: d18, recipe: r_smoothie,      use_recipe_quantity: true, day_food_group: grp_matin)
DayFood.create!(  day: d18, food: f["Oeuf entier"],   quantity: 200,             day_food_group: grp_matin)
DayRecipe.create!(day: d18, recipe: r_bol_poulet,     use_recipe_quantity: true, day_food_group: grp_dejeuner)
DayFood.create!(  day: d18, food: f["Noix"],          quantity: 30,              day_food_group: grp_collation)
DayFood.create!(  day: d18, food: f["Skyr nature"],   quantity: 250,             day_food_group: grp_collation)
DayFood.create!(  day: d18, food: f["Myrtilles surgelées"], quantity: 80,        day_food_group: grp_collation)
DayRecipe.create!(day: d18, recipe: r_bolognaise,     use_recipe_quantity: true, day_food_group: grp_diner)

# ── April 19 — Samedi — Pull B ────────────────────────────────────────────────
d19 = Day.create!(user: user, date: Date.new(2026, 4, 19),
                  energy_level: 5, mood: 5, sleep_quality: 5,
                  water_ml: 3200, steps: 13_000)

seed_session(d19, duration: 68, rpe: 8, sets_data: [
  [row,      6, 75.0], [row,      6, 75.0], [row,      5, 77.5], [row,      5, 77.5],
  [pulldown,10, 65.0], [pulldown,10, 65.0], [pulldown,10, 67.5], [pulldown,9, 67.5],
  [pullup_ex,10, nil], [pullup_ex,10, nil], [pullup_ex, 9, nil],
  [curl,     10, 25.0], [curl,    10, 25.0], [curl,    10, 25.0], [curl,    9, 25.0],
  [shrug,    15, 80.0], [shrug,   15, 80.0], [shrug,   14, 80.0],
])

DayRecipe.create!(day: d19, recipe: r_overnight_oats,  use_recipe_quantity: true, day_food_group: grp_matin)
DayFood.create!(  day: d19, food: f["Banane"],          quantity: 100,             day_food_group: grp_matin)
DayRecipe.create!(day: d19, recipe: r_quinoa_bowl,      use_recipe_quantity: true, day_food_group: grp_dejeuner)
DayFood.create!(  day: d19, food: f["Amandes"],         quantity: 50,              day_food_group: grp_collation)
DayFood.create!(  day: d19, food: f["Poire"],           quantity: 180,             day_food_group: grp_collation)
DayRecipe.create!(day: d19, recipe: r_salade_thon,      use_recipe_quantity: true, day_food_group: grp_diner)
DayFood.create!(  day: d19, food: f["Patate douce"],    quantity: 250,             day_food_group: grp_diner)
DayFood.create!(  day: d19, food: f["Chocolat noir 85%"], quantity: 40,            day_food_group: grp_diner)

# ── April 20 — Dimanche — Repos ───────────────────────────────────────────────
d20 = Day.create!(user: user, date: Date.new(2026, 4, 20),
                  energy_level: 4, mood: 4, sleep_quality: 5,
                  water_ml: 2200, steps: 5_200,
                  note: "Dimanche tranquille, priorité récupération et digestion.")

DayRecipe.create!(day: d20, recipe: r_omelette,        use_recipe_quantity: true, day_food_group: grp_matin)
DayFood.create!(  day: d20, food: f["Avoine (flocons)"], quantity: 60,            day_food_group: grp_matin)
DayFood.create!(  day: d20, food: f["Myrtilles surgelées"], quantity: 100,        day_food_group: grp_matin)
DayRecipe.create!(day: d20, recipe: r_patate_saumon,   use_recipe_quantity: true, day_food_group: grp_dejeuner)
DayFood.create!(  day: d20, food: f["Noix de cajou"],  quantity: 30,              day_food_group: grp_collation)
DayFood.create!(  day: d20, food: f["Fromage blanc 0%"], quantity: 200,           day_food_group: grp_collation)
DayFood.create!(  day: d20, food: f["Fraises"],        quantity: 150,             day_food_group: grp_collation)
DayRecipe.create!(day: d20, recipe: r_salade_grecque,  use_recipe_quantity: true, day_food_group: grp_diner)
DayFood.create!(  day: d20, food: f["Lentilles cuites"], quantity: 150,           day_food_group: grp_diner)

# ─────────────────────────────────────────────────────────────────────────────
# WEIGHT TRACKING  — 13 pesées hebdomadaires sur ~90 jours
# Progression réaliste muscle_gain : +0.3 kg/semaine avec légère variance
# ─────────────────────────────────────────────────────────────────────────────
user.weight_entries.destroy_all

start_date   = Date.new(2026, 4, 20) - 84  # 12 semaines en arrière = 26 jan 2026
start_weight = 77.6                         # poids de départ (< goal 85 kg)

13.times do |i|
  weigh_date = start_date + (i * 7)
  next if weigh_date > Date.today

  # Tendance : +0.3 kg/semaine + bruit aléatoire ±0.4 kg
  noise  = [-0.4, -0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3, 0.4].sample
  weight = (start_weight + i * 0.30 + noise).round(1)

  WeightEntry.create!(user: user, date: weigh_date, weight_kg: weight)
end

puts "  ✓ #{user.weight_entries.count} pesées (#{user.weight_entries.minimum(:date)} → #{user.weight_entries.maximum(:date)})"

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
puts ""
puts "  ✓ #{user.days.count} jours de calendrier (#{user.days.minimum(:date)} → #{user.days.maximum(:date)})"
puts "  ✓ #{DayFood.joins(:day).where(days: { user: user }).count} DayFoods"
puts "  ✓ #{DayRecipe.joins(:day).where(days: { user: user }).count} DayRecipes"
puts "  ✓ #{WorkoutSession.joins(:day).where(days: { user: user }).count} séances d'entraînement"
puts ""
puts "Seeding terminé ✓"
