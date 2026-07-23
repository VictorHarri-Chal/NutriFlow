module Exports
  # Not date-scoped, catalog-style like Foods. Produces two sheets: recipe
  # totals, and their ingredient breakdown.
  class RecipesExporter
    def initialize(user:, period: nil)
      @user = user
    end

    def sheets
      [recipes_sheet, ingredients_sheet]
    end

    private

    def recipes
      @recipes ||= @user.recipes.includes(recipe_items: :food, recipe_ratings: []).to_a
    end

    def recipes_sheet
      headers = [
        "Nom", "Poids total (g)", "Calories", "Protéines (g)", "Glucides (g)", "Lipides (g)",
        "Sucres (g)", "Fibres (g)", "AG saturés (g)", "Sel (g)", "Note moyenne", "Nb avis"
      ]
      rows = recipes.map do |r|
        ratings = r.recipe_ratings
        [
          r.name, r.total_weight, r.total_calories, r.total_proteins, r.total_carbs, r.total_fats,
          r.total_sugars, r.total_fiber, r.total_saturated_fat, r.total_salt,
          ratings.any? ? (ratings.sum(&:rating).to_f / ratings.size).round(1) : nil,
          ratings.size
        ]
      end
      Exports::Sheet.simple(name: "Recettes", headers: headers, rows: rows)
    end

    def ingredients_sheet
      headers = ["Recette", "Aliment", "Quantité", "Unité"]
      rows = recipes.flat_map do |r|
        r.recipe_items.map { |item| [r.name, item.food.name, item.quantity, item.unit] }
      end
      Exports::Sheet.simple(name: "Recettes - Ingrédients", headers: headers, rows: rows)
    end
  end
end
