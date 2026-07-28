module Exports
  class NutritionSummaryExporter
    def initialize(user:, period: nil)
      @user = user
      @period = period
    end

    def sheets
      logged_days = scoped_days.select { |d| d.day_foods.any? || d.day_recipes.any? }
      n = logged_days.size
      dates = logged_days.map(&:date).sort

      headers = [
        "Période", "Jours loggés / Total jours", "Moyenne calories",
        "Moyenne protéines (g)", "Moyenne glucides (g)", "Moyenne lipides (g)",
        "Streak actuel (jours)", "Meilleur streak (jours)"
      ]
      row = [
        period_label,
        "#{n} / #{total_days}",
        n.positive? ? (logged_days.sum(&:total_calories) / n).round : nil,
        n.positive? ? (logged_days.sum(&:total_proteins) / n).round(1) : nil,
        n.positive? ? (logged_days.sum(&:total_carbs) / n).round(1) : nil,
        n.positive? ? (logged_days.sum(&:total_fats) / n).round(1) : nil,
        Exports::StreakCalculator.current(dates),
        Exports::StreakCalculator.best(dates)
      ]

      [Exports::Sheet.simple(name: "Résumé - Nutrition", headers: headers, rows: [row])]
    end

    private

    def scoped_days
      @scoped_days ||= begin
        scope = @user.days.includes(day_foods: :food, day_recipes: { day_recipe_items: :food })
        range = @period&.range
        (range ? scope.where(date: range) : scope).to_a
      end
    end

    def total_days
      range = @period&.range
      return (range.last - range.first).to_i + 1 if range

      earliest = @user.days.minimum(:date)
      return 0 unless earliest

      (Date.today - earliest).to_i + 1
    end

    def period_label
      range = @period&.range
      range ? "#{I18n.l(range.first)} → #{I18n.l(range.last)}" : "Tout l'historique"
    end
  end
end
