module Exports
  # Not date-scoped: the food library isn't a log, it's a catalog — always
  # exported in full.
  class FoodsExporter
    def initialize(user:, period: nil)
      @user = user
    end

    def sheets
      headers = [
        "Nom", "Marque", "Catégorie", "Calories/100g", "Protéines/100g (g)",
        "Glucides/100g (g)", "Lipides/100g (g)", "Sucres/100g (g)", "Fibres/100g (g)",
        "AG saturés/100g (g)", "Sel/100g (g)", "Labels", "Allergènes", "Traces", "Source"
      ]

      rows = @user.foods.includes(:food_labels).order(:name).map do |food|
        [
          food.name, food.brand, food.category, food.calories, food.proteins,
          food.carbs, food.fats, food.sugars, food.fiber, food.saturated_fat, food.salt,
          food.food_labels.map(&:name).join(", "),
          food.allergens.join(", "),
          food.traces.join(", "),
          food.source.to_s
        ]
      end

      [Exports::Sheet.simple(name: "Aliments", headers: headers, rows: rows)]
    end
  end
end
