module Exports
  # Same logic as StatisticsController's private calc_current_streak /
  # calc_best_streak, kept as its own class since exporters can't call a
  # controller's private methods and duplicating it once here beats every
  # exporter reimplementing it.
  class StreakCalculator
    def self.current(sorted_dates)
      return 0 if sorted_dates.empty?

      date_set = sorted_dates.to_set
      streak = 0
      check = Date.today
      while date_set.include?(check)
        streak += 1
        check -= 1.day
      end
      streak
    end

    def self.best(sorted_dates)
      return 0 if sorted_dates.empty?

      best = current = 1
      sorted_dates.each_cons(2) do |a, b|
        if (b - a).to_i == 1
          current += 1
          best = current if current > best
        else
          current = 1
        end
      end
      best
    end
  end
end
