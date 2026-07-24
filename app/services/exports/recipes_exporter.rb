module Exports
  # Not date-scoped, catalog-style like Foods. One flat, human-readable sheet:
  # a row per recipe with its ingredients listed inline (name + quantity + unit),
  # its totals, its rating, and its preparation instructions — no separate
  # ingredients tab to cross-reference.
  class RecipesExporter
    def initialize(user:, period: nil)
      @user = user
    end

    def sheets
      headers = [
        "Nom", "Ingrédients", "Poids total (g)", "Calories", "Protéines (g)", "Glucides (g)",
        "Lipides (g)", "Sucres (g)", "Fibres (g)", "AG saturés (g)", "Sel (g)",
        "Note moyenne", "Nb avis", "Instructions"
      ]
      rows = recipes.map do |r|
        ratings = r.recipe_ratings
        [
          r.name, ingredients_text(r), r.total_weight, r.total_calories, r.total_proteins,
          r.total_carbs, r.total_fats, r.total_sugars, r.total_fiber, r.total_saturated_fat, r.total_salt,
          ratings.any? ? (ratings.sum(&:rating).to_f / ratings.size).round(1) : nil,
          ratings.size, r.instructions
        ]
      end
      [Exports::Sheet.simple(name: "Recettes", headers: headers, rows: rows)]
    end

    private

    def recipes
      @recipes ||= @user.recipes.includes(recipe_items: :food, recipe_ratings: []).order(:name).to_a
    end

    # "Blanc de poulet (200 g), Riz basmati cuit (250 g), Brocoli (150 g)…"
    def ingredients_text(recipe)
      recipe.recipe_items.map { |item| "#{item.food.name} (#{quantity_label(item)})" }.join(", ")
    end

    def quantity_label(item)
      qty = item.quantity
      # quantity is a BigDecimal — coerce to Integer/Float before interpolation,
      # otherwise a non-whole value renders in scientific notation ("0.2505e3").
      qty = qty == qty.to_i ? qty.to_i : qty.to_f
      "#{qty} #{item.unit}".strip
    end
  end
end
