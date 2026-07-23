module Exports
  # Date-scoped. Two sheets: one row per Day (metadata + daily totals), one
  # row per logged food/recipe entry (DayFood and DayRecipe share the same
  # duck-typed interface — see architecture doc's "Dual Entry System").
  class JournalExporter
    def initialize(user:, period: nil)
      @user = user
      @period = period
    end

    def sheets
      [days_sheet, entries_sheet]
    end

    private

    def days
      @days ||= scoped_days.to_a
    end

    def scoped_days
      scope = @user.days.includes(
        day_foods: [:food, :day_food_group],
        day_recipes: [{ recipe: { recipe_items: :food } }, { day_recipe_items: :food }, :day_food_group]
      ).order(:date)
      range = @period&.range
      range ? scope.where(date: range) : scope
    end

    def days_sheet
      headers = ["Date", "Note", "Énergie", "Humeur", "Sommeil", "Pas", "Eau (ml)", "Calories totales", "Protéines (g)", "Glucides (g)", "Lipides (g)"]
      rows = days.map do |day|
        [
          day.date, day.note, day.energy_level, day.mood, day.sleep_quality, day.steps, day.water_ml,
          day.total_calories, day.total_proteins, day.total_carbs, day.total_fats
        ]
      end
      Exports::Sheet.simple(name: "Journal - Jours", headers: headers, rows: rows)
    end

    def entries_sheet
      headers = [
        "Date", "Groupe de repas", "Type", "Nom", "Quantité", "Calories", "Protéines (g)",
        "Glucides (g)", "Lipides (g)", "Sucres (g)", "Fibres (g)", "AG saturés (g)", "Sel (g)"
      ]
      rows = days.flat_map { |day| entry_rows(day) }
      Exports::Sheet.simple(name: "Journal - Aliments & recettes", headers: headers, rows: rows)
    end

    def entry_rows(day)
      day.day_foods.map { |e| entry_row(day, e, "Aliment") } +
        day.day_recipes.map { |e| entry_row(day, e, "Recette") }
    end

    def entry_row(day, entry, type)
      [
        day.date, entry.day_food_group&.name, type, entry.food_name, entry.display_quantity,
        entry.total_calories, entry.total_proteins, entry.total_carbs, entry.total_fats,
        entry.total_sugars, entry.total_fiber, entry.total_saturated_fat, entry.total_salt
      ]
    end
  end
end
