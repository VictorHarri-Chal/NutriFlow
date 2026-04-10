# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# ──────────────────────────────────────────
# Utilisateur principal
# ──────────────────────────────────────────
user = User.find_or_create_by!(email: "victorharrichal@yahoo.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end

user.create_profile! unless user.profile

# Groupes de repas
%w[Petit-Déjeuner Déjeuner Collations Dîner].each do |name|
  DayFoodGroup.find_or_create_by!(name: name, user: user)
end

# Labels
label_proteine   = FoodLabel.find_or_create_by!(name: "Protéine",  user: user)
label_glucide    = FoodLabel.find_or_create_by!(name: "Glucide",   user: user)
label_lipide     = FoodLabel.find_or_create_by!(name: "Lipide",    user: user)
label_condiment  = FoodLabel.find_or_create_by!(name: "Condiment", user: user)

# ──────────────────────────────────────────
# Données nutritionnelles (valeurs / 100g)
# format: [nom, kcal, proteines, lipides, glucides, sucres, labels]
# ──────────────────────────────────────────
foods_data = [
  # 🔴 Protéines
  ["Petits suisses",         87,  9.0, 4.5,  5.0,  4.5, [label_proteine]],
  ["Graine de chia",        486, 17.0, 31.0, 42.0,  0.5, [label_proteine]],
  ["Skyr",                   57,  8.8,  0.2,  4.0,  4.0, [label_proteine]],
  ["Oeuf entier",           155, 13.0, 11.0,  0.7,  0.7, [label_proteine]],
  ["Viande hachée 5%",      130, 20.0,  5.0,  0.0,  0.0, [label_proteine]],
  ["Poulet (blanc)",        110, 23.0,  2.5,  0.0,  0.0, [label_proteine]],
  ["Pois chiche",           122,  6.7,  2.5, 18.0,  3.0, [label_proteine]],
  ["Thon en boite (eau)",   113, 26.0,  1.0,  0.0,  0.0, [label_proteine]],
  ["Féta",                  283, 15.0, 23.0,  0.0,  0.0, [label_proteine]],
  ["Oeuf dur",              155, 13.0, 11.0,  0.7,  0.7, [label_proteine]],
  ["Cottage cheese",         98, 11.0,  4.5,  3.0,  3.0, [label_proteine]],
  ["Sardine en boite",      185, 22.0, 11.0,  0.0,  0.0, [label_proteine]],
  ["Lentille (cuite)",      116,  9.0,  0.4, 20.0,  1.5, [label_proteine]],
  ["Lait soja protéiné",     39,  3.3,  1.8,  2.5,  1.5, [label_proteine]],

  # 🟡 Glucides
  ["Pomme",                  52,  0.3,  0.2, 13.0, 10.0, [label_glucide]],
  ["Poire",                  55,  0.4,  0.2, 13.0, 10.0, [label_glucide]],
  ["Myrtille surgelée",      57,  0.7,  0.3, 14.0, 10.0, [label_glucide]],
  ["Framboise surgelée",     34,  1.2,  0.3,  8.0,  5.0, [label_glucide]],
  ["Fruits rouges surgelés", 45,  1.0,  0.3, 11.0,  8.0, [label_glucide]],
  ["Patate douce",           86,  1.6,  0.1, 20.0,  4.0, [label_glucide]],
  ["Oignon",                 40,  1.1,  0.1,  9.0,  5.0, [label_glucide]],
  ["Ail",                   149,  6.4,  0.5, 33.0,  1.0, [label_glucide]],
  ["Concombre",              15,  0.6,  0.1,  3.6,  2.0, [label_glucide]],
  ["Maïs en conserve",       76,  2.8,  1.2, 16.0,  5.0, [label_glucide]],
  ["Champignon de paris",    22,  3.1,  0.3,  3.0,  2.0, [label_glucide]],
  ["Carotte",                41,  0.9,  0.2,  9.6,  5.0, [label_glucide]],
  ["Avoine",                370, 13.0,  7.0, 60.0,  1.0, [label_glucide]],
  ["Riz complet (cru)",     350,  7.5,  2.5, 72.0,  0.5, [label_glucide]],
  ["Pâte complète (crue)",  350, 13.0,  2.5, 68.0,  3.0, [label_glucide]],
  ["Tomate",                 18,  0.9,  0.2,  3.5,  3.0, [label_glucide]],
  ["Brocoli surgelé",        35,  3.0,  0.4,  6.0,  2.0, [label_glucide]],
  ["Haricots verts",         31,  1.8,  0.2,  6.0,  2.0, [label_glucide]],

  # 🟤 Lipides
  ["Amande",                579, 21.0, 50.0, 22.0,  4.0, [label_lipide]],
  ["Noix",                  654, 15.0, 65.0,  7.0,  2.0, [label_lipide]],
  ["Chocolat noir 70%",     566,  9.5, 42.0, 46.0, 28.0, [label_lipide]],
  ["Huile d'olive",         900,  0.0,100.0,  0.0,  0.0, [label_lipide]],
  ["Avocat",                160,  2.0, 15.0,  9.0,  0.5, [label_lipide]],

  # 🟠 Condiments
  ["Miel",                  304,  0.3,  0.0, 82.0, 82.0, [label_condiment]],
  ["Cannelle",              247,  4.0,  1.5, 55.0,  2.0, [label_condiment]],
  ["Poudre à lever",         53,  0.0,  0.0, 12.0,  0.0, [label_condiment]],
  ["Paprika",               282, 14.0, 13.0, 54.0, 10.0, [label_condiment]],
  ["Sauce soja",             60,  6.0,  0.0,  8.0,  3.0, [label_condiment]],
  ["Cumin",                 375, 18.0, 22.0, 44.0,  2.0, [label_condiment]],
  ["Cornichon",              22,  1.2,  0.2,  3.5,  1.0, [label_condiment]],
  ["Vinaigre balsamique",    88,  0.5,  0.0, 17.0, 14.0, [label_condiment]],
  ["Persil",                 36,  3.0,  0.8,  6.0,  1.0, [label_condiment]],
  ["Curcuma",               354,  8.0, 10.0, 65.0,  3.0, [label_condiment]],
  ["Herbes de provence",    265, 10.0,  6.0, 42.0,  5.0, [label_condiment]],
]

user.foods.destroy_all

foods_data.each do |name, calories, proteins, fats, carbs, sugars, labels|
  food = Food.create!(
    name:      name,
    calories:  calories,
    proteins:  proteins,
    fats:      fats,
    carbs:     carbs,
    sugars:    sugars,
    user:      user
  )
  food.food_labels << labels
end

puts "#{user.foods.count} aliments créés pour #{user.email}"
puts "Seeding terminé"
