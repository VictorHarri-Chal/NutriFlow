# db/seeds.rb — NutriFlow comprehensive demo seed
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

# Enable sections if the columns exist
user.update!(show_workout_section: true) if user.respond_to?(:show_workout_section=)
user.update!(show_cardio_section:  true) if user.respond_to?(:show_cardio_section=)

# ─────────────────────────────────────────────────────────────────────────────
# CLEAR PREVIOUS DATA
# ─────────────────────────────────────────────────────────────────────────────
user.days.destroy_all
user.workout_programs.destroy_all
user.exercise_favorites.destroy_all
user.recipes.destroy_all
user.foods.destroy_all
user.day_food_groups.destroy_all
user.food_labels.destroy_all
user.weight_entries.destroy_all

# ─────────────────────────────────────────────────────────────────────────────
# FOOD LABELS
# ─────────────────────────────────────────────────────────────────────────────
lbl_proteine  = FoodLabel.create!(name: "Protéine",  user: user, color: "green")
lbl_glucide   = FoodLabel.create!(name: "Glucide",   user: user, color: "amber")
lbl_lipide    = FoodLabel.create!(name: "Lipide",    user: user, color: "orange")
lbl_condiment = FoodLabel.create!(name: "Condiment", user: user, color: "blue")
lbl_fibre     = FoodLabel.create!(name: "Fibre",     user: user, color: "teal")

# ─────────────────────────────────────────────────────────────────────────────
# MEAL GROUPS
# ─────────────────────────────────────────────────────────────────────────────
grp_matin     = DayFoodGroup.create!(name: "Petit-Déjeuner", user: user)
grp_dejeuner  = DayFoodGroup.create!(name: "Déjeuner",       user: user)
grp_collation = DayFoodGroup.create!(name: "Collation",      user: user)
grp_diner     = DayFoodGroup.create!(name: "Dîner",          user: user)

grp = { matin: grp_matin, dejeuner: grp_dejeuner, collation: grp_collation, diner: grp_diner }

# ─────────────────────────────────────────────────────────────────────────────
# FOODS  (valeurs / 100g : kcal, prot, lip, glu, suc)
# ─────────────────────────────────────────────────────────────────────────────
foods_data = [
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
  ["Avoine (flocons)",        370,  13.0,  7.0, 60.0,  1.0, [lbl_glucide, lbl_fibre]],
  ["Riz complet (cru)",       350,   7.5,  2.5, 72.0,  0.5, [lbl_glucide]],
  ["Pâte complète (crue)",    350,  13.0,  2.5, 68.0,  3.0, [lbl_glucide, lbl_fibre]],
  ["Riz basmati (cru)",       358,   7.0,  0.8, 80.0,  0.3, [lbl_glucide]],
  ["Patate douce",             86,   1.6,  0.1, 20.0,  4.0, [lbl_glucide]],
  ["Pain de seigle",          259,   9.0,  3.5, 48.0,  3.0, [lbl_glucide, lbl_fibre]],
  ["Quinoa (cuit)",           120,   4.4,  1.9, 22.0,  1.0, [lbl_glucide, lbl_proteine]],
  ["Banane",                   89,   1.1,  0.3, 23.0, 12.0, [lbl_glucide]],
  ["Pomme",                    52,   0.3,  0.2, 13.0, 10.0, [lbl_glucide]],
  ["Poire",                    55,   0.4,  0.2, 13.0, 10.0, [lbl_glucide]],
  ["Myrtilles surgelées",      57,   0.7,  0.3, 14.0, 10.0, [lbl_glucide]],
  ["Fruits rouges surgelés",   45,   1.0,  0.3, 11.0,  8.0, [lbl_glucide]],
  ["Fraises",                  33,   0.7,  0.3,  8.0,  5.5, [lbl_glucide]],
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
  ["Amandes",                 579,  21.0, 50.0, 22.0,  4.0, [lbl_lipide]],
  ["Noix",                    654,  15.0, 65.0,  7.0,  2.0, [lbl_lipide]],
  ["Noix de cajou",           553,  18.0, 44.0, 33.0,  6.0, [lbl_lipide]],
  ["Chocolat noir 85%",       566,  12.5, 47.0, 29.0, 10.0, [lbl_lipide]],
  ["Huile d'olive",           900,   0.0,100.0,  0.0,  0.0, [lbl_lipide]],
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
  fo = Food.create!(name: name, calories: kcal, proteins: prot,
                    fats: lip, carbs: glu, sugars: suc, user: user)
  fo.food_labels << labels
  food_map[name] = fo
end
f = food_map
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

r_poulet_patate = build_recipe(user, "Poulet Grillé Patate Douce", [
  [f["Poulet (blanc)"],    220],
  [f["Patate douce"],      300],
  [f["Courgette"],         150],
  [f["Huile d'olive"],      12],
  [f["Herbes de Provence"],  3],
])

r_riz_sardines = build_recipe(user, "Riz Basmati Sardines Poivron", [
  [f["Riz basmati (cru)"],   90],
  [f["Sardines en boite"],  130],
  [f["Poivron rouge"],      120],
  [f["Oignon"],              60],
  [f["Sauce soja"],          15],
])

puts "  ✓ #{user.recipes.count} recettes"

# ─────────────────────────────────────────────────────────────────────────────
# RECIPE RATINGS
# ─────────────────────────────────────────────────────────────────────────────
[
  [r_overnight_oats,  5],
  [r_smoothie,        4],
  [r_bol_poulet,      5],
  [r_quinoa_bowl,     4],
  [r_bolognaise,      5],
  [r_curry_lentilles, 4],
  [r_salade_grecque,  3],
  [r_salade_thon,     4],
  [r_patate_saumon,   5],
  [r_poulet_patate,   5],
  [r_riz_sardines,    3],
].each do |recipe, rating|
  RecipeRating.find_or_create_by!(user: user, recipe: recipe) { |rr| rr.rating = rating }
end
puts "  ✓ #{RecipeRating.where(user: user).count} notes de recettes"

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

ppl = WorkoutProgram.create!(user: user, name: "PPL — Push Pull Legs", split_type: "ppl", is_active: true)
pd  = ppl.program_days.index_by(&:day_of_week)

seed_program_day(pd[0], "Push A", 60, [
  ["0025", 4,  8,  87.5, 120], ["0047", 3, 10, 72.5,  90],
  ["0086", 3, 10,  57.5,  90], ["0178", 3, 15, 13.5,  60],
  ["0056", 3, 12,  37.5,  75],
])
seed_program_day(pd[1], "Pull A", 65, [
  ["0027", 4,  8,  77.5, 120], ["0673", 3, 12, 70.0,  90],
  ["0015", 3, 12,   nil,  90], ["0023", 3, 12, 27.5,  60],
  ["0095", 3, 15,  80.0,  60],
])
seed_program_day(pd[2], "Legs", 70, [
  ["0024", 4,  6, 107.5, 150], ["0739", 3, 12, 135.0,  90],
  ["0054", 3, 10,  52.5,  75], ["0088", 4, 15,  47.5,  60],
  ["0001", 3, 20,   nil,  45],
])
pd[3].update!(name: nil)
seed_program_day(pd[4], "Push B", 60, [
  ["0025", 4,  6,  90.0, 150], ["0047", 3,  8, 75.0, 120],
  ["0086", 4, 12,  55.0,  90], ["0178", 4, 15, 14.0,  60],
  ["0056", 3, 15,  35.0,  60],
])
seed_program_day(pd[5], "Pull B", 65, [
  ["0027", 4,  6,  80.0, 150], ["0673", 4, 10, 72.5,  90],
  ["0015", 3, 12,   nil,  90], ["0023", 4, 10, 27.5,  60],
  ["0095", 3, 15,  82.5,  45],
])
pd[6].update!(name: nil)

ul  = WorkoutProgram.create!(user: user, name: "Upper / Lower 4j", split_type: "upper_lower", is_active: false)
ud  = ul.program_days.index_by(&:day_of_week)
seed_program_day(ud[0], "Upper A", 65, [
  ["0025", 4,  5,  90.0, 180], ["0027", 4,  5,  80.0, 180],
  ["0091", 3,  8,  60.0, 120], ["0673", 3, 10,  70.0,  90],
  ["0023", 3, 12,  27.5,  60], ["0056", 3, 12,  40.0,  60],
])
seed_program_day(ud[1], "Lower A", 70, [
  ["0024", 4,  5, 110.0, 180], ["0739", 3, 10, 135.0, 120],
  ["1010", 3,  8,  72.5, 120], ["0054", 3, 12,  52.5,  90],
  ["0605", 4, 20,  55.0,  60],
])
ud[2].update!(name: nil)
seed_program_day(ud[3], "Upper B", 65, [
  ["0025", 4,  8,  82.5, 120], ["0027", 4,  8,  75.0, 120],
  ["0091", 3, 10,  55.0,  90], ["0673", 4, 12,  65.0,  90],
  ["0023", 3, 15,  22.5,  60], ["0056", 3, 15,  35.0,  60],
])
seed_program_day(ud[4], "Lower B", 70, [
  ["0024", 4,  8, 102.5, 150], ["0739", 4, 12, 127.5,  90],
  ["1010", 3, 10,  67.5,  90], ["0054", 3, 10,  50.0,  75],
  ["0605", 3, 25,  52.5,  60],
])
ud[5].update!(name: nil)
ud[6].update!(name: nil)

puts "  ✓ 2 programmes créés"

# ─────────────────────────────────────────────────────────────────────────────
# CALENDAR HELPERS
# ─────────────────────────────────────────────────────────────────────────────

# Tracks heaviest weight ever lifted per exercise → auto-marks PRs
pr_tracker = Hash.new(0)

def seed_session(day, duration:, rpe:, sets_data:, tracker:)
  session = day.workout_sessions.build(duration_minutes: duration, rpe: rpe)
  sets_data.each_with_index do |(exercise, reps, weight), i|
    next unless exercise
    is_pr = weight.present? && weight.to_f > tracker[exercise.id]
    tracker[exercise.id] = weight.to_f if is_pr
    session.workout_sets.build(
      exercise: exercise, reps: reps, weight_kg: weight,
      position: i, is_pr: is_pr
    )
  end
  session.save!
end

def seed_cardio(day, machine:, duration:, **opts)
  cs = CardioSession.new(day: day)
  cs.cardio_blocks.build(machine: machine, duration_minutes: duration, **opts)
  cs.save!
end

# Meal rotation helpers — 4 breakfasts, 5 lunches, 4 snacks, 5 dinners
BFAST = [
  ->(d, f, r, g) {
    DayRecipe.create!(day: d, recipe: r[:overnight_oats], use_recipe_quantity: true, day_food_group: g[:matin])
  },
  ->(d, f, r, g) {
    DayRecipe.create!(day: d, recipe: r[:smoothie], use_recipe_quantity: true, day_food_group: g[:matin])
    DayFood.create!(day: d,  food: f["Oeuf entier"], quantity: 200, day_food_group: g[:matin])
  },
  ->(d, f, r, g) {
    DayRecipe.create!(day: d, recipe: r[:omelette], use_recipe_quantity: true, day_food_group: g[:matin])
    DayFood.create!(day: d,  food: f["Avoine (flocons)"], quantity: 60, day_food_group: g[:matin])
  },
  ->(d, f, r, g) {
    DayFood.create!(day: d, food: f["Avoine (flocons)"],    quantity: 80,  day_food_group: g[:matin])
    DayFood.create!(day: d, food: f["Skyr nature"],         quantity: 200, day_food_group: g[:matin])
    DayFood.create!(day: d, food: f["Myrtilles surgelées"], quantity: 100, day_food_group: g[:matin])
    DayFood.create!(day: d, food: f["Banane"],              quantity: 100, day_food_group: g[:matin])
  },
]

LUNCH = [
  ->(d, f, r, g) { DayRecipe.create!(day: d, recipe: r[:bol_poulet],     use_recipe_quantity: true, day_food_group: g[:dejeuner]) },
  ->(d, f, r, g) { DayRecipe.create!(day: d, recipe: r[:quinoa_bowl],    use_recipe_quantity: true, day_food_group: g[:dejeuner]) },
  ->(d, f, r, g) { DayRecipe.create!(day: d, recipe: r[:salade_thon],    use_recipe_quantity: true, day_food_group: g[:dejeuner])
                   DayFood.create!(day: d,   food: f["Pain de seigle"],   quantity: 80, day_food_group: g[:dejeuner]) },
  ->(d, f, r, g) { DayRecipe.create!(day: d, recipe: r[:patate_saumon],  use_recipe_quantity: true, day_food_group: g[:dejeuner]) },
  ->(d, f, r, g) { DayRecipe.create!(day: d, recipe: r[:poulet_patate],  use_recipe_quantity: true, day_food_group: g[:dejeuner]) },
]

SNACK = [
  ->(d, f, r, g) { DayFood.create!(day: d, food: f["Amandes"],          quantity: 40,  day_food_group: g[:collation])
                   DayFood.create!(day: d, food: f["Fromage blanc 0%"], quantity: 200, day_food_group: g[:collation]) },
  ->(d, f, r, g) { DayFood.create!(day: d, food: f["Noix de cajou"],    quantity: 35,  day_food_group: g[:collation])
                   DayFood.create!(day: d, food: f["Cottage cheese"],   quantity: 200, day_food_group: g[:collation]) },
  ->(d, f, r, g) { DayFood.create!(day: d, food: f["Skyr nature"],      quantity: 250, day_food_group: g[:collation])
                   DayFood.create!(day: d, food: f["Myrtilles surgelées"], quantity: 80, day_food_group: g[:collation]) },
  ->(d, f, r, g) { DayFood.create!(day: d, food: f["Beurre de cacahuète"], quantity: 30, day_food_group: g[:collation])
                   DayFood.create!(day: d, food: f["Pomme"],             quantity: 180, day_food_group: g[:collation]) },
]

DINNER = [
  ->(d, f, r, g) { DayRecipe.create!(day: d, recipe: r[:bolognaise],      use_recipe_quantity: true, day_food_group: g[:diner])
                   DayFood.create!(day: d,   food: f["Chocolat noir 85%"], quantity: 30, day_food_group: g[:diner]) },
  ->(d, f, r, g) { DayRecipe.create!(day: d, recipe: r[:curry_lentilles], use_recipe_quantity: true, day_food_group: g[:diner])
                   DayFood.create!(day: d,   food: f["Patate douce"],      quantity: 200, day_food_group: g[:diner]) },
  ->(d, f, r, g) { DayRecipe.create!(day: d, recipe: r[:salade_grecque],  use_recipe_quantity: true, day_food_group: g[:diner])
                   DayFood.create!(day: d,   food: f["Lentilles cuites"],  quantity: 150, day_food_group: g[:diner]) },
  ->(d, f, r, g) { DayRecipe.create!(day: d, recipe: r[:riz_sardines],    use_recipe_quantity: true, day_food_group: g[:diner])
                   DayFood.create!(day: d,   food: f["Chocolat noir 85%"], quantity: 40, day_food_group: g[:diner]) },
  ->(d, f, r, g) { DayRecipe.create!(day: d, recipe: r[:quinoa_bowl],     use_recipe_quantity: true, day_food_group: g[:diner]) },
]

def log_meals(idx, day, food_map, recipe_map, grp)
  BFAST[idx % 4].call(day, food_map, recipe_map, grp)
  LUNCH[idx % 5].call(day, food_map, recipe_map, grp)
  SNACK[idx % 4].call(day, food_map, recipe_map, grp)
  DINNER[idx % 5].call(day, food_map, recipe_map, grp)
end

# ─────────────────────────────────────────────────────────────────────────────
# EXERCISE OBJECTS
# ─────────────────────────────────────────────────────────────────────────────
ex     = ->(eid) { Exercise.find_by(exercise_id: eid) }
bench      = ex.("0025")   # barbell bench press
incline    = ex.("0047")   # incline bench press
ohp        = ex.("0086")   # overhead press (behind head)
ohp_seated = ex.("0091")   # seated overhead press
lat_raise  = ex.("0178")   # cable lateral raise
triceps    = ex.("0056")   # lying triceps extension
row        = ex.("0027")   # barbell bent-over row
pulldown   = ex.("0673")   # lat pulldown reverse grip
pullup_ex  = ex.("0015")   # parallel close-grip pull-up
curl       = ex.("0023")   # alternate biceps curl
shrug      = ex.("0095")   # barbell shrug
squat      = ex.("0024")   # front squat
leg_press  = ex.("0739")   # leg press 45°
lunge      = ex.("0054")   # barbell lunge
calf       = ex.("0088")   # seated calf raise
situp      = ex.("0001")   # 3/4 sit-up

recipe_map = {
  overnight_oats: r_overnight_oats,
  smoothie:       r_smoothie,
  omelette:       r_omelette,
  bol_poulet:     r_bol_poulet,
  quinoa_bowl:    r_quinoa_bowl,
  bolognaise:     r_bolognaise,
  curry_lentilles: r_curry_lentilles,
  salade_grecque: r_salade_grecque,
  salade_thon:    r_salade_thon,
  patate_saumon:  r_patate_saumon,
  poulet_patate:  r_poulet_patate,
  riz_sardines:   r_riz_sardines,
}

# ─────────────────────────────────────────────────────────────────────────────
# PROGRESSIVE OVERLOAD TABLE  — 14 weeks (w0 = Jan 13, w13 = Apr 14)
# Columns: bench, incline, ohp, row, pulldown, curl, squat, leg_press, lunge, calf
# ─────────────────────────────────────────────────────────────────────────────
PROG = [
  [72.5, 57.5, 42.5, 60.0, 55.0, 20.0,  85.0, 110.0, 40.0, 37.5],  # w0  Jan 13
  [75.0, 60.0, 45.0, 62.5, 57.5, 20.0,  87.5, 112.5, 42.5, 37.5],  # w1  Jan 20
  [75.0, 60.0, 45.0, 62.5, 57.5, 22.5,  90.0, 115.0, 42.5, 40.0],  # w2  Jan 27
  [77.5, 62.5, 47.5, 65.0, 60.0, 22.5,  90.0, 117.5, 45.0, 40.0],  # w3  Feb 3
  [77.5, 62.5, 47.5, 65.0, 60.0, 22.5,  92.5, 120.0, 45.0, 40.0],  # w4  Feb 10
  [80.0, 65.0, 50.0, 67.5, 62.5, 22.5,  92.5, 122.5, 47.5, 42.5],  # w5  Feb 17
  [80.0, 65.0, 50.0, 67.5, 62.5, 25.0,  95.0, 125.0, 47.5, 42.5],  # w6  Feb 24
  [82.5, 67.5, 50.0, 70.0, 65.0, 25.0,  97.5, 127.5, 47.5, 42.5],  # w7  Mar 3
  [82.5, 67.5, 52.5, 70.0, 65.0, 25.0, 100.0, 127.5, 50.0, 45.0],  # w8  Mar 10
  [85.0, 70.0, 52.5, 72.5, 67.5, 27.5, 100.0, 130.0, 50.0, 45.0],  # w9  Mar 17
  [85.0, 70.0, 55.0, 72.5, 67.5, 27.5, 102.5, 132.5, 50.0, 45.0],  # w10 Mar 24
  [87.5, 72.5, 55.0, 75.0, 70.0, 27.5, 105.0, 132.5, 52.5, 47.5],  # w11 Mar 31
  [87.5, 72.5, 57.5, 75.0, 70.0, 27.5, 107.5, 135.0, 52.5, 47.5],  # w12 Apr 7
  [87.5, 72.5, 57.5, 77.5, 70.0, 27.5, 107.5, 135.0, 52.5, 47.5],  # w13 Apr 14
]

# Cardio schedule per week: [thursday_config, sunday_config or nil]
# thursday_config / sunday_config: [machine, duration, opts_hash]
CARDIO_SCHEDULE = [
  [["bike",        25, { resistance_level: 7  }], nil],  # w0
  [["bike",        27, { resistance_level: 8  }], nil],  # w1
  [["bike",        28, { resistance_level: 8  }], ["outdoor_run", 30, { speed_kmh: 9.0 }]],  # w2
  [["treadmill",   30, { speed_kmh: 9.0,  incline_percent: 1 }], nil],  # w3
  [["treadmill",   30, { speed_kmh: 9.0,  incline_percent: 1 }], nil],  # w4
  [["treadmill",   32, { speed_kmh: 9.0,  incline_percent: 2 }], ["rower", 25, { resistance_level: 6 }]],  # w5
  [["treadmill",   35, { speed_kmh: 9.5,  incline_percent: 2 }], nil],  # w6
  [["treadmill",   35, { speed_kmh: 9.5,  incline_percent: 2 }], nil],  # w7
  [["rower",       30, { resistance_level: 7  }], ["outdoor_run", 35, { speed_kmh: 9.5 }]],  # w8
  [["rower",       35, { resistance_level: 7  }], nil],  # w9
  [["rower",       35, { resistance_level: 8  }], nil],  # w10
  [["elliptical",  30, { resistance_level: 9  }], ["outdoor_run", 40, { speed_kmh: 10.0 }]],  # w11
  [["bike",        30, { resistance_level: 10 }], nil],  # w12
  [["bike",        30, { resistance_level: 10 }], nil],  # w13
]

# Wellbeing data cycling arrays
ENERGY    = [3, 4, 5, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 3, 4, 5, 3, 4]
MOOD      = [4, 4, 5, 3, 4, 5, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 5, 3]
SLEEP_Q   = [4, 3, 5, 4, 4, 3, 5, 4, 3, 4, 5, 4, 4, 5, 3, 4, 4, 5]
WATER_ML  = [2600, 2800, 3000, 2400, 2700, 2900, 2500, 3200, 2800, 2600, 3000, 2400, 2700, 3100]
STEPS     = [8_200, 9_400, 11_500, 6_800, 9_100, 7_500, 13_000, 8_800, 10_200, 7_200, 9_600, 5_800, 8_500, 12_000]

WEEK_START = Date.new(2026, 1, 13)  # Monday week 0

# ─────────────────────────────────────────────────────────────────────────────
# GENERATE 14 WEEKS OF CALENDAR DATA
# ─────────────────────────────────────────────────────────────────────────────
day_counter = 0

14.times do |w|
  p      = PROG[w]
  wstart = WEEK_START + w * 7

  bench_w, incline_w, ohp_w, row_w, pulldown_w, curl_w, squat_w, leg_press_w, lunge_w, calf_w = p

  # Pull-up reps increase over time (6 → 13)
  pullup_reps = 6 + (w * 0.5).floor

  # ── Monday — Push A ──────────────────────────────────────────────────────
  d_mon = Day.create!(user: user, date: wstart,
    energy_level: ENERGY[(w * 2) % 18], mood: MOOD[(w * 3) % 18],
    sleep_quality: SLEEP_Q[(w * 2 + 1) % 18],
    water_ml: WATER_ML[w % 14], steps: STEPS[w % 14])

  seed_session(d_mon, duration: 60 + (w % 3), rpe: 7 + (w % 3 == 0 ? 1 : 0), tracker: pr_tracker, sets_data: [
    [bench, 8, bench_w], [bench, 8, bench_w], [bench, 7, bench_w - 2.5], [bench, 6, bench_w - 2.5],
    [incline, 10, incline_w], [incline, 10, incline_w], [incline,  9, incline_w - 2.5],
    [ohp, 10, ohp_w], [ohp, 10, ohp_w], [ohp, 9, ohp_w - 2.5],
    [lat_raise, 15, 12.5], [lat_raise, 15, 12.5], [lat_raise, 14, 12.5],
    [triceps, 12, 35.0 + (w / 4) * 2.5], [triceps, 12, 35.0 + (w / 4) * 2.5], [triceps, 11, 32.5 + (w / 4) * 2.5],
  ])
  log_meals(w * 7 + 0, d_mon, food_map, recipe_map, grp)

  # ── Tuesday — Pull A ──────────────────────────────────────────────────────
  d_tue = Day.create!(user: user, date: wstart + 1,
    energy_level: ENERGY[(w * 2 + 1) % 18], mood: MOOD[(w * 2) % 18],
    sleep_quality: SLEEP_Q[(w * 3) % 18],
    water_ml: WATER_ML[(w + 1) % 14], steps: STEPS[(w + 2) % 14])

  seed_session(d_tue, duration: 65, rpe: 7, tracker: pr_tracker, sets_data: [
    [row, 8, row_w], [row, 8, row_w], [row, 7, row_w - 2.5], [row, 7, row_w - 2.5],
    [pulldown, 12, pulldown_w], [pulldown, 12, pulldown_w], [pulldown, 10, pulldown_w - 2.5],
    [pullup_ex, pullup_reps, nil], [pullup_ex, pullup_reps - 1, nil], [pullup_ex, [pullup_reps - 2, 4].max, nil],
    [curl, 12, curl_w], [curl, 12, curl_w], [curl, 11, curl_w - 2.5],
    [shrug, 12, 80.0], [shrug, 12, 80.0], [shrug, 12, 82.5],
  ])
  log_meals(w * 7 + 1, d_tue, food_map, recipe_map, grp)

  # ── Wednesday — Legs ──────────────────────────────────────────────────────
  d_wed = Day.create!(user: user, date: wstart + 2,
    energy_level: ENERGY[(w + 3) % 18], mood: MOOD[(w * 2 + 1) % 18],
    sleep_quality: SLEEP_Q[(w + 5) % 18],
    water_ml: WATER_ML[(w + 3) % 14], steps: STEPS[(w + 4) % 14])

  seed_session(d_wed, duration: 70 + (w % 5), rpe: 8 + (w % 4 == 0 ? 1 : 0), tracker: pr_tracker, sets_data: [
    [squat, 6, squat_w], [squat, 6, squat_w], [squat, 5, squat_w + 2.5], [squat, 5, squat_w],
    [leg_press, 12, leg_press_w], [leg_press, 12, leg_press_w], [leg_press, 11, leg_press_w + 2.5],
    [lunge, 10, lunge_w], [lunge, 10, lunge_w], [lunge, 9, lunge_w],
    [calf, 15, calf_w], [calf, 15, calf_w], [calf, 15, calf_w + 2.5], [calf, 14, calf_w + 2.5],
    [situp, 20, nil], [situp, 20, nil], [situp, 18, nil],
  ])
  log_meals(w * 7 + 2, d_wed, food_map, recipe_map, grp)

  # ── Thursday — Rest + Cardio ──────────────────────────────────────────────
  thu_note = w.even? ? nil : "Journée calme, focus récupération."
  d_thu = Day.create!(user: user, date: wstart + 3,
    energy_level: ENERGY[(w + 6) % 18], mood: MOOD[(w + 7) % 18],
    sleep_quality: SLEEP_Q[(w * 2 + 3) % 18],
    water_ml: WATER_ML[(w + 5) % 14], steps: STEPS[(w + 6) % 14],
    note: thu_note)

  thu_cardio = CARDIO_SCHEDULE[w][0]
  seed_cardio(d_thu, machine: thu_cardio[0], duration: thu_cardio[1], **thu_cardio[2].transform_keys(&:to_sym))
  log_meals(w * 7 + 3, d_thu, food_map, recipe_map, grp)

  # ── Friday — Push B ───────────────────────────────────────────────────────
  d_fri = Day.create!(user: user, date: wstart + 4,
    energy_level: ENERGY[(w + 9) % 18], mood: MOOD[(w * 3 + 1) % 18],
    sleep_quality: SLEEP_Q[(w + 8) % 18],
    water_ml: WATER_ML[(w + 7) % 14], steps: STEPS[(w + 8) % 14])

  seed_session(d_fri, duration: 58, rpe: 8, tracker: pr_tracker, sets_data: [
    [bench, 6, bench_w + 2.5], [bench, 6, bench_w + 2.5], [bench, 5, bench_w + 2.5], [bench, 5, bench_w],
    [incline, 8, incline_w + 2.5], [incline, 8, incline_w + 2.5], [incline, 7, incline_w],
    [ohp, 12, ohp_w], [ohp, 12, ohp_w], [ohp, 11, ohp_w], [ohp, 10, ohp_w - 2.5],
    [lat_raise, 15, 13.0], [lat_raise, 15, 13.0], [lat_raise, 14, 13.0], [lat_raise, 14, 12.5],
    [triceps, 15, 30.0 + (w / 4) * 2.5], [triceps, 15, 30.0 + (w / 4) * 2.5], [triceps, 14, 30.0 + (w / 4) * 2.5],
  ])
  log_meals(w * 7 + 4, d_fri, food_map, recipe_map, grp)

  # ── Saturday — Pull B ─────────────────────────────────────────────────────
  d_sat = Day.create!(user: user, date: wstart + 5,
    energy_level: ENERGY[(w + 11) % 18], mood: MOOD[(w + 12) % 18],
    sleep_quality: SLEEP_Q[(w * 3 + 2) % 18],
    water_ml: WATER_ML[(w + 9) % 14], steps: STEPS[(w + 10) % 14])

  seed_session(d_sat, duration: 68, rpe: 8, tracker: pr_tracker, sets_data: [
    [row, 6, row_w + 2.5], [row, 6, row_w + 2.5], [row, 5, row_w + 2.5], [row, 5, row_w],
    [pulldown, 10, pulldown_w + 2.5], [pulldown, 10, pulldown_w + 2.5], [pulldown, 10, pulldown_w], [pulldown, 9, pulldown_w],
    [pullup_ex, pullup_reps, nil], [pullup_ex, pullup_reps, nil], [pullup_ex, pullup_reps - 1, nil],
    [curl, 10, curl_w], [curl, 10, curl_w], [curl, 10, curl_w], [curl, 9, curl_w - 2.5],
    [shrug, 15, 82.5], [shrug, 15, 82.5], [shrug, 14, 82.5],
  ])
  log_meals(w * 7 + 5, d_sat, food_map, recipe_map, grp)

  # ── Sunday — Rest (+ cardio some weeks) ───────────────────────────────────
  sun_cardio_config = CARDIO_SCHEDULE[w][1]
  sun_note = sun_cardio_config.nil? ? "Repos complet, alimentation propre." : nil
  d_sun = Day.create!(user: user, date: wstart + 6,
    energy_level: ENERGY[(w + 14) % 18], mood: MOOD[(w + 15) % 18],
    sleep_quality: SLEEP_Q[(w + 16) % 18],
    water_ml: WATER_ML[(w + 11) % 14], steps: STEPS[(w + 12) % 14],
    note: sun_note)

  if sun_cardio_config
    seed_cardio(d_sun, machine: sun_cardio_config[0], duration: sun_cardio_config[1], **sun_cardio_config[2].transform_keys(&:to_sym))
  end
  log_meals(w * 7 + 6, d_sun, food_map, recipe_map, grp)

  day_counter += 7
end

puts "  ✓ #{user.days.count} jours (#{user.days.minimum(:date)} → #{user.days.maximum(:date)})"
puts "  ✓ #{WorkoutSession.joins(:day).where(days: { user: user }).count} séances d'entraînement"
puts "  ✓ #{CardioSession.joins(:day).where(days: { user: user }).count} sessions cardio"
puts "  ✓ #{WorkoutSet.joins(workout_session: :day).where(days: { user: user }, is_pr: true).count} PRs"

# ─────────────────────────────────────────────────────────────────────────────
# WEIGHT TRACKING  — pesée hebdomadaire sur 14 semaines
# Progression muscle_gain : +0.3 kg/semaine ± variance réaliste
# ─────────────────────────────────────────────────────────────────────────────
noise_seq = [-0.3, 0.1, -0.2, 0.2, -0.1, 0.3, 0.0, -0.4, 0.2, 0.1, -0.3, 0.2, 0.0, 0.3]

15.times do |i|
  weigh_date = WEEK_START + i * 7
  next if weigh_date > Date.today
  weight = (77.6 + i * 0.30 + noise_seq[i % 14]).round(1)
  WeightEntry.create!(user: user, date: weigh_date, weight_kg: weight)
end

puts "  ✓ #{user.weight_entries.count} pesées (#{user.weight_entries.minimum(:date)} → #{user.weight_entries.maximum(:date)})"

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
puts ""
puts "  ✓ #{user.foods.count} aliments • #{user.recipes.count} recettes • #{user.exercise_favorites.count} favoris"
puts "  ✓ #{DayFood.joins(:day).where(days: { user: user }).count} DayFoods logged"
puts "  ✓ #{DayRecipe.joins(:day).where(days: { user: user }).count} DayRecipes logged"
puts ""
puts "NutriFlow seed terminé ✓"
