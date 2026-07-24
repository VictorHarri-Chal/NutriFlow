# db/seeds.rb — NutriFlow comprehensive demo seed
#
# Builds a fully populated demo account spanning ~2 years so every duration
# filter, statistic and export category has data to show. Idempotent: reuses
# User#reset_all_data! to wipe the demo user's data before rebuilding.
#
#   bin/rails db:seed                       # default demo email (local only)
#   SEED_EMAIL=me@example.com bin/rails db:seed
#   FORCE_SEED=1 bin/rails db:seed          # required to run in production
#
# Derived values are never written directly: Profile#goal follows goal_weight
# vs weight, Profile#weight follows the latest WeightEntry, cardio/workout
# calories are recomputed on save. We only feed raw inputs.

require "date"

# Destructive: wipes the target account before rebuilding. Local by default;
# allowed in production only with an explicit opt-in (e.g. for a demo account).
if Rails.env.production? && ENV["FORCE_SEED"].blank?
  abort("⛔  Seed de démo bloqué en production. Relancez avec FORCE_SEED=1 si c'est volontaire (ex: compte de démo).")
end

Bullet.enable = false if defined?(Bullet)

RNG   = Random.new(20_260_723)
TODAY = Date.current
START = (TODAY - 2.years)

pick    = ->(arr)      { arr[RNG.rand(arr.size)] }
sample  = ->(arr, n)   { arr.shuffle(random: RNG).first(n) }
chance  = ->(p)        { RNG.rand < p }
between = ->(lo, hi)   { lo + RNG.rand * (hi - lo) }
intbtw  = ->(lo, hi)   { RNG.rand(lo..hi) }
round25 = ->(x)        { (x / 2.5).round * 2.5 }

puts "🌱  Seeding NutriFlow demo account (#{START} → #{TODAY})…"

# ─────────────────────────────────────────────────────────────────────────────
# USER + PROFILE
# ─────────────────────────────────────────────────────────────────────────────
email = ENV.fetch("SEED_EMAIL", "victorharrichal@yahoo.com")
user  = User.find_or_initialize_by(email: email)
if user.new_record?
  user.password = user.password_confirmation = "password123"
  user.skip_confirmation!               # sets confirmed_at, no mailer
  user.skip_confirmation_notification!  # avoids Devise mapping error in seed context
  user.save!
end
user.update_columns(
  confirmed_at: user.confirmed_at || Time.current,
  locale:       "fr",
  time_zone:    "Europe/Paris"
)

puts "  ↺ Resetting existing data for #{email}…"
user.reset_all_data!
user.reload

user.update!(
  show_day_note:          true,
  show_workout_section:   true,
  show_cardio_section:    true,
  show_water_tracking:    true,
  show_tdee_breakdown:    true,
  show_weight_tracking:   true,
  show_body_measurements: true,
  show_fasting_tracking:  true
)
user.update_column(:fasting_disclaimer_acknowledged_at, Time.current)

# goal_weight (90) > weight (78) ⇒ goal auto-derives to muscle_gain.
# Latest WeightEntry later overwrites Profile#weight to the final trend value.
user.profile.update!(
  name:                  "Victor",
  date_of_birth:         Date.new(1997, 4, 12),
  height:                178,
  gender:                :male,
  weight:                78,
  goal_weight:           90,
  goal_rate_kg_per_week: 0.15,
  job_activity_level:    :light_activity,
  water_goal_ml:         2500,
  default_daily_steps:   8_000
)

# ─────────────────────────────────────────────────────────────────────────────
# FOOD LABELS
# ─────────────────────────────────────────────────────────────────────────────
labels = {
  proteine:   FoodLabel.create!(user:, name: "Protéine",   color: "green"),
  glucide:    FoodLabel.create!(user:, name: "Glucide",    color: "amber"),
  lipide:     FoodLabel.create!(user:, name: "Lipide",     color: "orange"),
  legume:     FoodLabel.create!(user:, name: "Légume",     color: "teal"),
  fruit:      FoodLabel.create!(user:, name: "Fruit",      color: "red"),
  laitier:    FoodLabel.create!(user:, name: "Laitier",    color: "blue"),
  condiment:  FoodLabel.create!(user:, name: "Condiment",  color: "violet"),
  complement: FoodLabel.create!(user:, name: "Complément", color: "yellow")
}

# ─────────────────────────────────────────────────────────────────────────────
# MEAL GROUPS
# ─────────────────────────────────────────────────────────────────────────────
groups = {
  petit_dej:  DayFoodGroup.create!(user:, name: "Petit-déjeuner"),
  dejeuner:   DayFoodGroup.create!(user:, name: "Déjeuner"),
  diner:      DayFoodGroup.create!(user:, name: "Dîner"),
  collation:  DayFoodGroup.create!(user:, name: "Collation"),
  post_train: DayFoodGroup.create!(user:, name: "Post-entraînement")
}

# ─────────────────────────────────────────────────────────────────────────────
# FOOD BANK (macros per 100 g)
# ─────────────────────────────────────────────────────────────────────────────
# [key, name, category, cal, prot, carb, sugar, fat, extra]
food_defs = [
  [:poulet,        "Blanc de poulet",         "proteins",    120, 23.0, 0.0,  0.0,   2.6,  { label: :proteine, micros: { "potassium" => 250, "zinc" => 1.0 } }],
  [:boeuf,         "Steak haché 5%",          "proteins",    137, 21.0, 0.0,  0.0,   5.0,  { label: :proteine, micros: { "iron" => 2.6, "zinc" => 4.8, "vitamin_b12" => 2.5 } }],
  [:saumon,        "Saumon frais",            "proteins",    208, 20.0, 0.0,  0.0,  13.0,  { label: :proteine, micros: { "epa" => 0.7, "dha" => 1.1, "vitamin_d" => 11 } }],
  [:thon,          "Thon au naturel",         "proteins",    116, 26.0, 0.0,  0.0,   1.0,  { label: :proteine, brand: "Petit Navire", source: "off", off_id: "3107872001618", nutriscore: "b", nova: 3 }],
  [:oeuf,          "Œuf entier",              "proteins",    143, 12.6, 0.7,  0.7,   9.9,  { label: :proteine, micros: { "vitamin_b12" => 1.1, "vitamin_a" => 160, "vitamin_d" => 2 } }],
  [:tofu,          "Tofu nature",             "proteins",    144, 15.0, 2.0,  0.5,   8.0,  { label: :proteine, source: "ciqual" }],
  [:jambon,        "Jambon blanc",            "proteins",    110, 18.0, 1.0,  1.0,   3.5,  { label: :proteine, brand: "Herta", source: "off", nutriscore: "c", nova: 4 }],
  [:crevette,      "Crevettes cuites",        "proteins",     99, 24.0, 0.2,  0.0,   0.3,  { label: :proteine }],
  [:whey,          "Whey protéine vanille",   "supplements", 380, 78.0, 8.0,  4.0,   6.0,  { label: :complement, brand: "MyProtein", source: "off", favorite: true }],
  [:skyr,          "Skyr nature",             "dairy",        63, 11.0, 4.0,  4.0,   0.2,  { label: :laitier, brand: "Danone", nutriscore: "a", micros: { "calcium" => 150 } }],
  [:fromage_blanc, "Fromage blanc 3%",        "dairy",        75,  8.0, 4.5,  4.5,   3.0,  { label: :laitier, micros: { "calcium" => 110 } }],
  [:mozza,         "Mozzarella",              "dairy",       280, 18.0, 1.0,  1.0,  22.0,  { label: :laitier }],
  [:parmesan,      "Parmesan",                "dairy",       402, 33.0, 0.0,  0.0,  29.0,  { label: :laitier, micros: { "calcium" => 1180 } }],
  [:lait,          "Lait demi-écrémé",        "dairy",        46,  3.3, 4.8,  4.8,   1.5,  { label: :laitier }],
  [:riz,           "Riz basmati cuit",        "grains",      130,  2.7, 28.0, 0.1,   0.3,  { label: :glucide }],
  [:pates,         "Pâtes complètes cuites",  "grains",      124,  5.0, 25.0, 1.0,   1.1,  { label: :glucide, micros: { "magnesium" => 43 } }],
  [:patate,        "Patate douce",            "vegetables",   86,  1.6, 20.0, 4.2,   0.1,  { label: :glucide, micros: { "vitamin_a" => 709 } }],
  [:pdt,           "Pomme de terre",          "vegetables",   77,  2.0, 17.0, 0.8,   0.1,  { label: :glucide }],
  [:pain,          "Pain complet",            "grains",      247,  9.0, 41.0, 3.0,   3.4,  { label: :glucide, micros: { "magnesium" => 76 } }],
  [:flocons,       "Flocons d'avoine",        "grains",      389, 13.0, 60.0, 1.0,   7.0,  { label: :glucide, micros: { "magnesium" => 138, "iron" => 4.7 }, favorite: true }],
  [:quinoa,        "Quinoa cuit",             "grains",      120,  4.4, 21.0, 0.9,   1.9,  { label: :glucide }],
  [:semoule,       "Semoule cuite",           "grains",      112,  3.8, 23.0, 0.3,   0.2,  { label: :glucide }],
  [:brocoli,       "Brocoli",                 "vegetables",   34,  2.8, 7.0,  1.7,   0.4,  { label: :legume, micros: { "vitamin_c" => 89, "vitamin_b9" => 63 } }],
  [:epinard,       "Épinards",                "vegetables",   23,  2.9, 3.6,  0.4,   0.4,  { label: :legume, micros: { "iron" => 2.7, "vitamin_a" => 469 } }],
  [:courgette,     "Courgette",               "vegetables",   17,  1.2, 3.1,  2.5,   0.3,  { label: :legume }],
  [:tomate,        "Tomate",                  "vegetables",   18,  0.9, 3.9,  2.6,   0.2,  { label: :legume, micros: { "vitamin_c" => 14, "potassium" => 237 } }],
  [:carotte,       "Carotte",                 "vegetables",   41,  0.9, 10.0, 4.7,   0.2,  { label: :legume, micros: { "vitamin_a" => 835 } }],
  [:salade,        "Salade verte",            "vegetables",   15,  1.4, 2.9,  0.8,   0.2,  { label: :legume }],
  [:poivron,       "Poivron rouge",           "vegetables",   31,  1.0, 6.0,  4.2,   0.3,  { label: :legume, micros: { "vitamin_c" => 128 } }],
  [:haricot,       "Haricots verts",          "vegetables",   31,  1.8, 7.0,  3.3,   0.1,  { label: :legume }],
  [:lentilles,     "Lentilles cuites",        "vegetables",  116,  9.0, 20.0, 1.8,   0.4,  { label: :proteine, micros: { "iron" => 3.3, "vitamin_b9" => 181 } }],
  [:pois_chiche,   "Pois chiches",            "vegetables",  164,  8.9, 27.0, 4.8,   2.6,  { label: :proteine }],
  [:banane,        "Banane",                  "fruits",       89,  1.1, 23.0, 12.0,  0.3,  { label: :fruit, micros: { "potassium" => 358 }, favorite: true }],
  [:pomme,         "Pomme",                   "fruits",       52,  0.3, 14.0, 10.0,  0.2,  { label: :fruit }],
  [:myrtille,      "Myrtilles",               "fruits",       57,  0.7, 14.0, 10.0,  0.3,  { label: :fruit, micros: { "vitamin_c" => 10 } }],
  [:fraise,        "Fraises",                 "fruits",       33,  0.7, 8.0,  4.9,   0.3,  { label: :fruit, micros: { "vitamin_c" => 59 } }],
  [:orange,        "Orange",                  "fruits",       47,  0.9, 12.0, 9.0,   0.1,  { label: :fruit, micros: { "vitamin_c" => 53 } }],
  [:avocat,        "Avocat",                  "fruits",      160,  2.0, 9.0,  0.7,  15.0,  { label: :lipide, micros: { "potassium" => 485 } }],
  [:amande,        "Amandes",                 "other",       579, 21.0, 22.0, 4.4,  50.0,  { label: :lipide, micros: { "magnesium" => 270, "calcium" => 269 } }],
  [:noix,          "Noix",                    "other",       654, 15.0, 14.0, 2.6,  65.0,  { label: :lipide, micros: { "magnesium" => 158 } }],
  [:beurre_cac,    "Beurre de cacahuète",     "other",       588, 25.0, 20.0, 9.0,  50.0,  { label: :lipide, brand: "Whole Earth", source: "off", nova: 3, favorite: true }],
  [:huile,         "Huile d'olive",           "condiments",  900,  0.0, 0.0,  0.0, 100.0,  { label: :lipide }],
  [:miel,          "Miel",                    "condiments",  304,  0.3, 82.0, 82.0,  0.0,  { label: :condiment }],
  [:chocolat,      "Chocolat noir 70%",       "other",       546,  7.8, 46.0, 24.0, 42.0,  { label: :lipide }],
  [:sauce_soja,    "Sauce soja",              "condiments",   53,  8.1, 4.9,  0.4,   0.6,  { label: :condiment, micros: { "sodium" => 5637 } }],
  [:cafe,          "Café noir",               "beverages",     2,  0.1, 0.0,  0.0,   0.0,  { in_pantry: false }],
  [:coca,          "Coca-Cola",               "beverages",    42,  0.0, 10.6, 10.6,  0.0,  { brand: "Coca-Cola", source: "off", off_id: "5449000000996", nutriscore: "e", nova: 4, in_pantry: false }],
  [:chips,         "Chips nature",            "other",       536,  6.6, 50.0, 0.6,  34.0,  { brand: "Lay's", source: "off", nutriscore: "d", nova: 4, in_pantry: false }],
  [:cookie,        "Cookie pépites chocolat", "other",       480,  5.5, 64.0, 35.0, 22.0,  { brand: "BN", source: "off", nutriscore: "e", nova: 4, in_pantry: false }]
]

foods = {}
food_defs.each do |key, name, cat, cal, prot, carb, sugar, fat, extra|
  extra ||= {}
  food = user.foods.create!(
    name:             name,
    category:         cat,
    calories:         cal,
    proteins:         prot,
    carbs:            carb,
    sugars:           sugar,
    fats:             fat,
    brand:            extra[:brand],
    source:           extra.fetch(:source, "manual"),
    off_id:           extra[:off_id],
    nutriscore_grade: extra[:nutriscore],
    nova_group:       extra[:nova],
    favorite:         extra.fetch(:favorite, false),
    in_pantry:        extra.fetch(:in_pantry, true),
    micronutrients:   extra.fetch(:micros, {})
  )
  food.food_labels << labels[extra[:label]] if extra[:label]
  foods[key] = food
end
all_foods = foods.values
puts "  ✓ #{all_foods.size} foods"

# ─────────────────────────────────────────────────────────────────────────────
# RECIPES (balanced, unbalanced, high-protein, treats…)
# ─────────────────────────────────────────────────────────────────────────────
def recipe!(user, name, instructions, favorite, items)
  user.recipes.create!(
    name: name, instructions: instructions, favorite: favorite,
    recipe_items_attributes: items.map { |food, qty| { food_id: food.id, quantity: qty, unit: "g" } }
  )
end

recipes = []
recipes << recipe!(user, "Poulet riz brocoli", "Cuire le riz, poêler le poulet, vapeur pour le brocoli.", true,
  [[foods[:poulet], 200], [foods[:riz], 250], [foods[:brocoli], 150], [foods[:huile], 10]])
recipes << recipe!(user, "Bowl saumon quinoa", "Assembler saumon, quinoa, avocat et épinards.", true,
  [[foods[:saumon], 150], [foods[:quinoa], 200], [foods[:avocat], 80], [foods[:epinard], 60]])
recipes << recipe!(user, "Omelette légumes", "Battre les œufs, ajouter poivron et tomate, cuire à feu doux.", false,
  [[foods[:oeuf], 180], [foods[:poivron], 80], [foods[:tomate], 80], [foods[:huile], 8]])
recipes << recipe!(user, "Porridge protéiné", "Cuire les flocons dans le lait, ajouter whey, banane et beurre de cacahuète.", true,
  [[foods[:flocons], 80], [foods[:lait], 250], [foods[:whey], 30], [foods[:banane], 100], [foods[:beurre_cac], 20]])
recipes << recipe!(user, "Dahl de lentilles", "Mijoter les lentilles et pois chiches avec tomate et carotte.", false,
  [[foods[:lentilles], 200], [foods[:pois_chiche], 100], [foods[:tomate], 120], [foods[:carotte], 80]])
recipes << recipe!(user, "Pâtes bolognaise", "Faire revenir le bœuf, ajouter la sauce tomate, servir sur les pâtes.", false,
  [[foods[:pates], 250], [foods[:boeuf], 150], [foods[:tomate], 150], [foods[:parmesan], 20]])
recipes << recipe!(user, "Salade de thon", "Mélanger thon, salade, tomate, huile d'olive.", false,
  [[foods[:thon], 120], [foods[:salade], 100], [foods[:tomate], 100], [foods[:huile], 10]])
recipes << recipe!(user, "Wrap poulet avocat", "Garnir le pain de poulet, avocat, salade.", false,
  [[foods[:pain], 100], [foods[:poulet], 120], [foods[:avocat], 60], [foods[:salade], 40]])
recipes << recipe!(user, "Tofu sauté sésame", "Poêler le tofu avec sauce soja, courgette et poivron.", false,
  [[foods[:tofu], 200], [foods[:courgette], 120], [foods[:poivron], 100], [foods[:sauce_soja], 20], [foods[:riz], 200]])
recipes << recipe!(user, "Skyr fruits rouges", "Mélanger skyr, myrtilles, fraises et miel.", true,
  [[foods[:skyr], 200], [foods[:myrtille], 60], [foods[:fraise], 60], [foods[:miel], 15]])
recipes << recipe!(user, "Steak patate douce", "Rôtir la patate douce, poêler le steak, haricots vapeur.", false,
  [[foods[:boeuf], 180], [foods[:patate], 250], [foods[:haricot], 120]])
recipes << recipe!(user, "Crevettes semoule", "Sauter les crevettes, servir sur semoule et courgette.", false,
  [[foods[:crevette], 150], [foods[:semoule], 200], [foods[:courgette], 120]])
recipes << recipe!(user, "Energy balls", "Mixer flocons, beurre de cacahuète, miel et chocolat, former des boules.", false,
  [[foods[:flocons], 100], [foods[:beurre_cac], 60], [foods[:miel], 40], [foods[:chocolat], 40]])
recipes << recipe!(user, "Mug cake chocolat", "Mélanger, cuire 1 min au micro-ondes. Pas très équilibré, mais bon.", false,
  [[foods[:chocolat], 50], [foods[:oeuf], 60], [foods[:flocons], 40], [foods[:miel], 30]])
recipes << recipe!(user, "Pizza maison", "Base tomate, mozzarella, jambon.", false,
  [[foods[:pain], 200], [foods[:mozza], 100], [foods[:tomate], 120], [foods[:jambon], 80]])
recipes << recipe!(user, "Shake post-training", "Whey, banane, lait, beurre de cacahuète au blender.", true,
  [[foods[:whey], 40], [foods[:banane], 120], [foods[:lait], 300], [foods[:beurre_cac], 15]])
recipes << recipe!(user, "Buddha bowl", "Quinoa, pois chiches, avocat, carotte, épinards.", true,
  [[foods[:quinoa], 180], [foods[:pois_chiche], 120], [foods[:avocat], 70], [foods[:carotte], 80], [foods[:epinard], 50]])
recipes << recipe!(user, "Œufs brouillés avoine", "Œufs brouillés + porridge salé pour le petit-déj costaud.", false,
  [[foods[:oeuf], 150], [foods[:flocons], 60], [foods[:lait], 150]])

# Ratings on a subset of recipes
rating_comments = [
  "Excellent, à refaire !", "Parfait après l'entraînement.", "Un peu trop copieux à mon goût.",
  "Simple et efficace.", "Manque un peu de goût, à assaisonner davantage.", "Mon repas préféré de la semaine."
]
sample.call(recipes, 10).each do |recipe|
  RecipeRating.create!(user:, recipe:, rating: intbtw.call(3, 5), comment: (chance.call(0.6) ? pick.call(rating_comments) : nil))
end
puts "  ✓ #{recipes.size} recipes (+ ratings)"

# ─────────────────────────────────────────────────────────────────────────────
# EXERCISES — custom + favorites (globals reused via accessible scope)
# ─────────────────────────────────────────────────────────────────────────────
# Precondition: workout/program seeding reuses the shared global Exercise catalog.
# Fail early and clearly rather than mid-transaction if it hasn't been imported.
abort("⛔  Aucun exercice global en base. Importez le catalogue d'exercices avant de lancer le seed.") if Exercise.global.none?

def ex_pool(part)
  Exercise.global.where(body_part: part).where.not(name_fr: [nil, ""]).limit(40).to_a
end

pools = {
  chest:     ex_pool("chest"),
  back:      ex_pool("back"),
  legs:      ex_pool("upper legs"),
  shoulders: ex_pool("shoulders"),
  arms:      ex_pool("upper arms"),
  core:      ex_pool("waist")
}
pools.transform_values! { |a| a.presence || Exercise.global.limit(10).to_a }

custom_defs = [
  ["Gainage lesté maison",     "waist",      "body weight", "abs"],
  ["Tirage élastique porte",   "back",       "band",        "lats"],
  ["Fentes bulgares haltères", "upper legs", "dumbbell",    "quads"]
]
custom_exercises = custom_defs.map.with_index do |(name, part, equip, target), i|
  Exercise.create!(
    exercise_id:    "custom-#{user.id}-#{i + 1}",
    custom_user_id: user.id,
    name:           name,
    name_fr:        name,
    body_part:      part,
    equipment:      equip,
    target_muscle:  target
  )
end

favorite_exercises = (sample.call(pools.values.flatten.uniq, 8) + custom_exercises).uniq
favorite_exercises.each { |ex| ExerciseFavorite.create!(user:, exercise: ex) }
puts "  ✓ #{custom_exercises.size} custom exercises, #{favorite_exercises.size} favorites"

# ─────────────────────────────────────────────────────────────────────────────
# WORKOUT PROGRAMS (update the 7 auto-created program_days)
# ─────────────────────────────────────────────────────────────────────────────
def build_program_day!(program, wday, name, exercises, rng, round25)
  day = program.program_days.find_by!(day_of_week: wday)
  day.update!(name: name, notes: (rng.rand < 0.4 ? "Focus technique et tempo contrôlé." : nil))
  exercises.compact.uniq.each do |ex|
    sets_n = rng.rand(3..4)
    base   = round25.call(20 + rng.rand * 40)
    sets_attrs = Array.new(sets_n) do |i|
      types = ["working"]
      types = ["warmup"]  if i.zero? && rng.rand < 0.5
      types = ["failure"] if i == sets_n - 1 && rng.rand < 0.25
      {
        reps_target:   types == ["warmup"] ? 12 : rng.rand(6..12),
        weight_target: ex.equipment == "body weight" ? nil : base,
        rpe:           types == ["warmup"] ? nil : rng.rand(7..9),
        set_types:     types
      }
    end
    # position on ProgramExercise/ProgramExerciseSet is assigned by before_create
    day.program_exercises.create!(
      exercise:     ex,
      rest_seconds: [60, 90, 120, 180].sample(random: rng),
      notes:        (rng.rand < 0.25 ? "Garder 1 à 2 reps en réserve." : nil),
      program_exercise_sets_attributes: sets_attrs
    )
  end
end

ppl = user.workout_programs.create!(name: "Push Pull Legs", split_type: "ppl", is_active: true)
build_program_day!(ppl, 0, "Push", sample.call(pools[:chest], 2) + sample.call(pools[:shoulders], 1) + sample.call(pools[:arms], 1), RNG, round25)
build_program_day!(ppl, 1, "Pull", sample.call(pools[:back], 3) + sample.call(pools[:arms], 1), RNG, round25)
build_program_day!(ppl, 2, "Legs", sample.call(pools[:legs], 3) + sample.call(pools[:core], 1), RNG, round25)
build_program_day!(ppl, 4, "Push", sample.call(pools[:chest], 2) + sample.call(pools[:shoulders], 1), RNG, round25)
build_program_day!(ppl, 5, "Pull", sample.call(pools[:back], 2) + sample.call(pools[:arms], 1), RNG, round25)

ul = user.workout_programs.create!(name: "Upper / Lower", split_type: "upper_lower", is_active: false)
build_program_day!(ul, 0, "Upper", sample.call(pools[:chest], 1) + sample.call(pools[:back], 1) + sample.call(pools[:shoulders], 1) + sample.call(pools[:arms], 1), RNG, round25)
build_program_day!(ul, 2, "Lower", sample.call(pools[:legs], 3) + sample.call(pools[:core], 1), RNG, round25)
build_program_day!(ul, 4, "Upper", sample.call(pools[:chest], 1) + sample.call(pools[:back], 2), RNG, round25)
build_program_day!(ul, 5, "Lower", sample.call(pools[:legs], 2) + sample.call(pools[:core], 1), RNG, round25)

fb = user.workout_programs.create!(name: "Full Body débutant", split_type: "fullbody", is_active: false)
build_program_day!(fb, 0, "Full Body A", [pools[:legs].first, pools[:chest].first, pools[:back].first, pools[:core].first], RNG, round25)
build_program_day!(fb, 3, "Full Body B", [pools[:legs].last, pools[:shoulders].first, pools[:back].last, pools[:arms].first], RNG, round25)
puts "  ✓ 3 workout programs"

# ─────────────────────────────────────────────────────────────────────────────
# CALENDAR — ~2 years of days (food, workouts, cardio, wellbeing, hydration)
# ─────────────────────────────────────────────────────────────────────────────
day_notes = [
  "Bonne journée, plein d'énergie.", "Fatigué, nuit courte.", "Grosse séance, très satisfait.",
  "Repas au restaurant ce midi.", "Journée off, récupération.", "Objectif protéines atteint.",
  "Un peu de stress au travail.", "Cheat meal assumé ce soir.", "Motivation au top."
]
workout_notes = ["Bonne progression sur les charges.", "Séance intense.", "Un peu fatigué mais séance bouclée.", "Nouveau record !", nil, nil]
cardio_notes  = ["Cardio tranquille.", "Séance HIIT.", "Récupération active.", nil, nil]
machines      = CardioBlock::MACHINES

# Per-exercise progressive working weight across the 2 years
working_weight = Hash.new { |h, k| h[k] = 20 + RNG.rand(0..8) * 2.5 }

# weekday (Ruby wday: 0=Sun..6=Sat) → strength focus
strength_focus = { 1 => :push, 2 => :pull, 4 => :legs, 5 => :upper }
cardio_wdays   = [3, 6]

def strength_exercises(focus, pools, sample)
  case focus
  when :push  then sample.call(pools[:chest], 2) + sample.call(pools[:shoulders], 1) + sample.call(pools[:arms], 1)
  when :pull  then sample.call(pools[:back], 3) + sample.call(pools[:arms], 1)
  when :legs  then sample.call(pools[:legs], 3) + sample.call(pools[:core], 1)
  else             sample.call(pools[:chest], 1) + sample.call(pools[:back], 1) + sample.call(pools[:shoulders], 1) + sample.call(pools[:legs], 1)
  end.compact.uniq
end

def cardio_block_attrs(machine, rng, between)
  attrs = { machine: machine, duration_minutes: rng.rand(20..45) }
  case machine
  when "treadmill"   then attrs.merge!(speed_kmh: between.call(8, 12).round(1), incline_percent: rng.rand(0..6))
  when "outdoor_run" then attrs.merge!(speed_kmh: between.call(9, 13).round(1), distance_km: between.call(4, 9).round(2))
  when "swimming"    then attrs.merge!(distance_km: between.call(0.8, 2.0).round(2))
  when "jump_rope"   then attrs.merge!(duration_minutes: rng.rand(10..20))
  else                    attrs.merge!(resistance_level: rng.rand(5..15))
  end
  attrs
end

# Realistic meals for a lean-bulk profile: protein at every meal, calorie
# surplus (~2600 kcal/day avg). Each entry is [food, grams]; portions scaled in log_meal.
breakfasts = [
  [[foods[:flocons], 90], [foods[:lait], 250], [foods[:whey], 30], [foods[:banane], 110], [foods[:beurre_cac], 20]],
  [[foods[:oeuf], 180], [foods[:pain], 90], [foods[:avocat], 60], [foods[:orange], 150]],
  [[foods[:skyr], 250], [foods[:flocons], 70], [foods[:myrtille], 70], [foods[:miel], 15], [foods[:amande], 25]],
  [[foods[:fromage_blanc], 250], [foods[:banane], 110], [foods[:flocons], 60], [foods[:beurre_cac], 20]]
]
lunches = [
  [[foods[:poulet], 220], [foods[:riz], 300], [foods[:brocoli], 150], [foods[:huile], 12]],
  [[foods[:boeuf], 200], [foods[:patate], 300], [foods[:haricot], 130], [foods[:huile], 8]],
  [[foods[:saumon], 180], [foods[:quinoa], 220], [foods[:epinard], 70], [foods[:avocat], 60]],
  [[foods[:poulet], 200], [foods[:pates], 250], [foods[:tomate], 120], [foods[:parmesan], 25], [foods[:huile], 8]]
]
dinners = [
  [[foods[:boeuf], 200], [foods[:pdt], 280], [foods[:courgette], 130], [foods[:huile], 10]],
  [[foods[:tofu], 220], [foods[:riz], 240], [foods[:poivron], 110], [foods[:sauce_soja], 20], [foods[:huile], 8]],
  [[foods[:crevette], 180], [foods[:semoule], 240], [foods[:courgette], 120], [foods[:huile], 8]],
  [[foods[:thon], 160], [foods[:pdt], 260], [foods[:salade], 80], [foods[:avocat], 60]],
  [[foods[:saumon], 180], [foods[:riz], 240], [foods[:haricot], 130]]
]
snacks = [
  [[foods[:amande], 30], [foods[:pomme], 150]],
  [[foods[:fromage_blanc], 200], [foods[:miel], 15]],
  [[foods[:banane], 120], [foods[:beurre_cac], 25]],
  [[foods[:skyr], 200], [foods[:fraise], 90]],
  [[foods[:noix], 25], [foods[:orange], 150]]
]
cheat_extras = [
  [[foods[:coca], 330], [foods[:chips], 60]],
  [[foods[:cookie], 60], [foods[:chocolat], 40]],
  [[foods[:coca], 330], [foods[:cookie], 50]]
]
dinner_recipe_names = [
  "Poulet riz brocoli", "Bowl saumon quinoa", "Dahl de lentilles", "Pâtes bolognaise",
  "Steak patate douce", "Crevettes semoule", "Tofu sauté sésame", "Buddha bowl",
  "Pizza maison", "Wrap poulet avocat"
]
dinner_recipes = recipes.select { |r| dinner_recipe_names.include?(r.name) }

food_day_count = 0
workout_count  = 0
cardio_count   = 0

ActiveRecord::Base.transaction do
  (START..TODAY).each do |date|
    puts "    … #{date.strftime('%Y-%m')}" if date.day == 1
    next if chance.call(0.07) # ~7% gap days: a meticulous logger, few holes

    day = user.days.create!(
      date:          date,
      water_ml:      intbtw.call(2000, 3400),
      steps:         intbtw.call(6000, 14_000),
      mood:          (chance.call(0.9) ? intbtw.call(3, 5) : nil),
      energy_level:  (chance.call(0.9) ? intbtw.call(3, 5) : nil),
      sleep_quality: (chance.call(0.9) ? intbtw.call(3, 5) : nil),
      note:          (chance.call(0.18) ? pick.call(day_notes) : nil)
    )

    # ── Meals (protein-rich surplus, ±8% portion jitter) ──
    food_day_count += 1
    # Center portions slightly above the template (~+12%) so the daily average
    # lands above the app's muscle-gain target (~2481 kcal) — a real surplus.
    log_meal = ->(group, items) do
      items.each { |food, grams| day.day_foods.create!(food:, day_food_group: group, quantity: (grams * between.call(1.05, 1.19)).round) }
    end

    log_meal.call(groups[:petit_dej], pick.call(breakfasts))
    log_meal.call(groups[:dejeuner],  pick.call(lunches))

    # Dinner: a logged recipe ~40% of days (keeps recipe-logging covered), else a plated meal
    if chance.call(0.40)
      recipe = pick.call(dinner_recipes)
      if chance.call(0.08)
        day.day_recipes.create!(
          recipe:, day_food_group: groups[:diner], customized: true,
          day_recipe_items_attributes: pick.call(dinners).map { |f, g| { food_id: f.id, quantity: g, unit: "g" } }
        )
      elsif chance.call(0.5)
        day.day_recipes.create!(recipe:, day_food_group: groups[:diner], use_recipe_quantity: true)
      else
        day.day_recipes.create!(recipe:, day_food_group: groups[:diner], quantity: intbtw.call(500, 650))
      end
    else
      log_meal.call(groups[:diner], pick.call(dinners))
    end

    log_meal.call(groups[:collation], pick.call(snacks)) if chance.call(0.85)
    log_meal.call(groups[:collation], pick.call(cheat_extras)) if chance.call(0.08) # occasional treat

    # ── Strength session ──
    focus = strength_focus[date.wday]
    if focus && !chance.call(0.10)
      exercises  = strength_exercises(focus, pools, sample)
      position   = 0
      sets_attrs = []
      exercises.each do |ex|
        # Slow progressive overload with occasional PR
        pr = false
        if chance.call(0.04)
          working_weight[ex.id] += 2.5
          pr = true
        end
        base   = ex.equipment == "body weight" ? nil : round25.call(working_weight[ex.id])
        sets_n = intbtw.call(3, 4)
        sets_n.times do |i|
          types = ["working"]
          types = ["warmup"]  if i.zero? && chance.call(0.4)
          types = ["failure"] if i == sets_n - 1 && chance.call(0.15)
          types = ["dropset"] if i == sets_n - 1 && types == ["working"] && chance.call(0.1)
          sets_attrs << {
            exercise_id:  ex.id,
            position:     position,
            reps:         (types == ["warmup"] ? 12 : intbtw.call(5, 12)),
            weight_kg:    base,
            rpe:          (types == ["warmup"] ? nil : intbtw.call(7, 9)),
            rest_seconds: pick.call([60, 90, 120, 180]),
            is_pr:        (pr && i == sets_n - 1),
            set_types:    types
          }
          position += 1
        end
      end
      day.workout_sessions.create!(
        duration_minutes:        intbtw.call(45, 80),
        notes:                   pick.call(workout_notes),
        workout_sets_attributes: sets_attrs
      )
      workout_count += 1
      # Post-workout shake logged into the dedicated meal slot
      day.day_foods.create!(food: foods[:whey], day_food_group: groups[:post_train], quantity: intbtw.call(35, 45)) if chance.call(0.8)
    end

    # ── Cardio session ──
    if cardio_wdays.include?(date.wday) && !chance.call(0.15)
      blocks_n = chance.call(0.2) ? 2 : 1
      blocks = Array.new(blocks_n) { |i| cardio_block_attrs(pick.call(machines), RNG, between).merge(position: i) }
      day.cardio_sessions.create!(notes: pick.call(cardio_notes), cardio_blocks_attributes: blocks)
      cardio_count += 1
    end
  end
end
puts "  ✓ #{food_day_count} logged days, #{workout_count} strength sessions, #{cardio_count} cardio sessions"

# ─────────────────────────────────────────────────────────────────────────────
# WEIGHT ENTRIES (trend 78 → ~86; latest overwrites Profile#weight)
# ─────────────────────────────────────────────────────────────────────────────
weight_count = 0
span = (TODAY - START).to_f
d = START
while d <= TODAY
  progress = (d - START).to_f / span
  w = 78 + progress * 8 + between.call(-0.6, 0.6)
  user.weight_entries.create!(date: d, weight_kg: w.round(1))
  weight_count += 1
  d += intbtw.call(2, 4)
end
puts "  ✓ #{weight_count} weight entries"

# ─────────────────────────────────────────────────────────────────────────────
# BODY MEASUREMENTS (every ~5 days, dense like weight; a few with diagrams)
# ─────────────────────────────────────────────────────────────────────────────
image_files = Dir[Rails.root.join("db/seeds/images/*.png")]
measurements = []
m = START
while m <= TODAY
  progress = (m - START).to_f / span
  # Lean-bulk coherence: circumferences grow with weight (78→86 kg); waist rises
  # only slightly (a little fat comes with the muscle), keeping body-fat plausible.
  measurements << user.body_measurements.create!(
    date:      m,
    waist_cm:  (81 + progress * 2.0 + between.call(-0.4, 0.4)).round(1),
    hips_cm:   (96 + progress * 2.0 + between.call(-0.4, 0.4)).round(1),
    chest_cm:  (99 + progress * 6.0 + between.call(-0.4, 0.4)).round(1),
    biceps_cm: (35 + progress * 3.5 + between.call(-0.3, 0.3)).round(1),
    thighs_cm: (56 + progress * 4.0 + between.call(-0.4, 0.4)).round(1),
    calves_cm: (37 + progress * 1.5 + between.call(-0.3, 0.3)).round(1),
    neck_cm:   (37 + progress * 1.0 + between.call(-0.2, 0.2)).round(1)
  )
  m += intbtw.call(4, 6)
end

# Attach placeholder diagrams to a spread of measurements (offsets counted from
# the newest), including recent ones so two photos show on the first history page.
if image_files.any?
  [1, 5, 30, 70, 115].each_with_index do |offset, i|
    next if offset >= measurements.size
    path = image_files[i % image_files.size]
    measurements[-1 - offset].image.attach(io: File.open(path), filename: File.basename(path), content_type: "image/png")
  end
end
puts "  ✓ #{measurements.size} body measurements"

# ─────────────────────────────────────────────────────────────────────────────
# FASTING SESSIONS (history + one active)
# ─────────────────────────────────────────────────────────────────────────────
protocol_hours = { "sixteen_eight" => 16, "eighteen_six" => 18, "omad" => 23, "circadian_12_12" => 12 }
fasting_count = 0
last_end = nil
fd = TODAY - 150
while fd < TODAY
  if chance.call(0.45)
    proto = pick.call(protocol_hours.keys)
    start = Time.zone.local(fd.year, fd.month, fd.day, 20, 0)
    if last_end.nil? || start > last_end # never overlap a previous fast
      last_end = start + (protocol_hours[proto] + between.call(-1.0, 2.0)).hours
      user.fasting_sessions.create!(protocol: proto, started_at: start, ended_at: last_end)
      fasting_count += 1
    end
  end
  fd += 1
end
# One currently active session
user.fasting_sessions.create!(protocol: "sixteen_eight", started_at: Time.zone.now - 5.hours)
fasting_count += 1
puts "  ✓ #{fasting_count} fasting sessions (1 active)"

# ─────────────────────────────────────────────────────────────────────────────
# SHOPPING LISTS (active + archived, mixed checked / food-linked / free-text)
# ─────────────────────────────────────────────────────────────────────────────
def add_list_items!(list, all_foods, rng)
  all_foods.sample(6, random: rng).each do |food|
    list.shopping_list_items.create!(
      food: food, name: food.name, quantity: "#{[100, 200, 250, 500, 1000].sample(random: rng)} g",
      category: food.category, checked: rng.rand < 0.4
    )
  end
  [["Sopalin", "condiments"], ["Sacs congélation", nil], ["Épices curry", "condiments"]].each do |name, cat|
    next unless rng.rand < 0.6
    list.shopping_list_items.create!(name: name, quantity: "1", category: cat, checked: rng.rand < 0.3)
  end
end

active1 = user.shopping_lists.create!(name: "Courses de la semaine")
add_list_items!(active1, all_foods, RNG)
active2 = user.shopping_lists.create!(name: "Batch cooking dimanche")
add_list_items!(active2, all_foods, RNG)

3.times do |i|
  archived = user.shopping_lists.create!(name: "Courses semaine -#{i + 1}", archived_at: (TODAY - (i + 1) * 7).to_time)
  add_list_items!(archived, all_foods, RNG)
end
puts "  ✓ 2 active + 3 archived shopping lists"

Bullet.enable = true if defined?(Bullet)

puts <<~SUMMARY

  ✅ Seed terminé pour #{email}
     Days:              #{user.days.count}
     Foods:             #{user.foods.count}
     Recipes:           #{user.recipes.count}
     Workout programs:  #{user.workout_programs.count}
     Weight entries:    #{user.weight_entries.count}
     Body measurements: #{user.body_measurements.count}
     Fasting sessions:  #{user.fasting_sessions.count}
     Shopping lists:    #{user.shopping_lists.count}
     Login: #{email} / password123
SUMMARY
