# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Création d'un utilisateur de test
user = User.find_or_create_by!(email: "test@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end

# Création des groupes de repas
day_food_groups = [
  "Petit-Déjeuner",
  "Déjeuner",
  "Collations",
  "Dîner"
]

day_food_groups.each do |group_name|
  DayFoodGroup.find_or_create_by!(name: group_name, user: user)
end

puts "Created #{day_food_groups.length} day food groups"

# Listes d'aliments et de marques pour la génération aléatoire
food_names = [
  "Pomme", "Banane", "Orange", "Poire", "Fraise", "Cerise", "Pêche", "Abricot", "Kiwi", "Ananas",
  "Bœuf haché", "Poulet grillé", "Saumon", "Thon", "Porc", "Agneau", "Crevettes", "Œuf", "Tofu", "Haricots rouges",
  "Riz blanc", "Riz complet", "Pâtes", "Pain blanc", "Pain complet", "Quinoa", "Avoine", "Orge", "Blé", "Semoule",
  "Lait entier", "Yaourt nature", "Fromage blanc", "Camembert", "Gruyère", "Mozzarella", "Beurre", "Crème fraîche", "Lait d'amande", "Yaourt grec",
  "Brocoli", "Carotte", "Courgette", "Épinards", "Salade", "Tomate", "Concombre", "Poivron", "Aubergine", "Champignon"
]

brands = [
  "Carrefour", "Monoprix", "Bio Village", "Fleury Michon", "Danone", "Président", "Bonduelle",
  "Herta", "Knorr", "Maggi", "Leader Price", "Système U", "Leclerc", "Auchan", nil
]

# Supprimer les aliments existants pour l'utilisateur de test
user.foods.destroy_all

# Génération des 50 aliments
50.times do
  food_name = food_names.sample
  Food.create!(
    name: food_name,
    brand: brands.sample,
    fats: rand(0.0..30.0).round(1),
    carbs: rand(0.0..80.0).round(1),
    sugars: rand(0.0..20.0).round(1),
    proteins: rand(0.0..40.0).round(1),
    calories: rand(20..500),
    user: user
  )
end

puts "Created #{user.foods.count} foods for user #{user.email}"
puts "Seeding completed"
