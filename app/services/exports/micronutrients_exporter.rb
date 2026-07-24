module Exports
  # Date-scoped. One row per logged day with that day's aggregated micronutrient
  # intake (the same 14 nutrients tracked in the app's stats). Columns that stay
  # empty for the whole period are dropped by ExcelBuilder, so a user who never
  # records e.g. vitamin D won't see a dead column.
  class MicronutrientsExporter
    def initialize(user:, period: nil)
      @user = user
      @period = period
    end

    def sheets
      headers = ["Date"] + Micronutrient::ALL.map { |entry| "#{entry.label} (#{entry.unit})" }
      rows = logged_days.map do |day|
        values = day.aggregated_micronutrients
        [day.date] + Micronutrient::ALL.map { |entry| values[entry.key.to_s].to_f.round(2) }
      end
      [Exports::Sheet.simple(name: "Micronutriments", headers: headers, rows: rows)]
    end

    private

    def logged_days
      scope = @user.days.includes(
        day_foods: :food,
        day_recipes: [{ recipe: { recipe_items: :food } }, { day_recipe_items: :food }]
      ).order(:date)
      range = @period&.range
      scope = scope.where(date: range) if range
      scope.to_a.select { |day| day.day_foods.any? || day.day_recipes.any? }
    end
  end
end
