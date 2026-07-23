module Exports
  class WellbeingSummaryExporter
    def initialize(user:, period: nil)
      @user = user
      @period = period
    end

    def sheets
      days    = scoped_days
      profile = @user.profile

      energy_vals = days.map(&:energy_level).compact
      mood_vals   = days.map(&:mood).compact
      sleep_vals  = days.map(&:sleep_quality).compact
      steps_days  = days.select { |d| d.steps.present? }
      water_days  = days.select { |d| d.water_ml.to_i > 0 }

      steps_goal = profile&.default_daily_steps.to_i
      water_goal = profile&.water_goal_ml.to_i

      avg_steps = steps_days.any? ? (steps_days.sum { |d| d.steps.to_i }.to_f / steps_days.size).round : nil
      avg_water = water_days.any? ? (water_days.sum { |d| d.water_ml.to_i }.to_f / water_days.size).round : nil

      steps_streak = Exports::StreakCalculator.current(
        steps_days.select { |d| d.steps.to_i >= steps_goal }.map(&:date).sort
      )
      water_streak = Exports::StreakCalculator.current(
        water_days.select { |d| d.water_ml.to_i >= water_goal }.map(&:date).sort
      )

      headers = [
        "Moyenne énergie (/5)", "Moyenne humeur (/5)", "Moyenne sommeil (/5)",
        "Moyenne pas", "% objectif pas atteint", "Streak pas (jours)",
        "Moyenne eau (ml)", "% objectif eau atteint", "Streak hydratation (jours)"
      ]
      row = [
        avg(energy_vals), avg(mood_vals), avg(sleep_vals),
        avg_steps, percentage(avg_steps, steps_goal), steps_streak,
        avg_water, percentage(avg_water, water_goal), water_streak
      ]

      [Exports::Sheet.simple(name: "Résumé - Bien-être", headers: headers, rows: [row])]
    end

    private

    def scoped_days
      @scoped_days ||= begin
        scope = @user.days
        range = @period&.range
        (range ? scope.where(date: range) : scope).to_a
      end
    end

    def avg(values)
      return nil if values.empty?

      (values.sum.to_f / values.size).round(1)
    end

    def percentage(value, goal)
      return nil unless value && goal&.positive?

      [(value.to_f / goal * 100).round, 100].min
    end
  end
end
