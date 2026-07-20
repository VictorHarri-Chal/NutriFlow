# frozen_string_literal: true

# Computes streak/history stats for a user's fasting sessions.
# Streaks are based on the calendar date a completed session *started* on.
class FastingStatsCalculator
  def initialize(user)
    @user = user
  end

  def call
    sessions        = user.fasting_sessions.completed.ordered
    completed_dates = sessions.select(&:reached_target?).map { |s| s.started_at.to_date }.uniq

    {
      current_streak:  current_streak(completed_dates),
      best_streak:     best_streak(completed_dates),
      total_hours:     sessions.sum(&:elapsed_hours).round(1),
      completion_rate: completion_rate(sessions)
    }
  end

  private

  attr_reader :user

  def current_streak(dates)
    return 0 if dates.empty?

    descending = dates.sort.reverse
    today = Date.current
    return 0 unless descending.first == today || descending.first == today - 1.day

    streak   = 0
    expected = descending.first
    descending.each do |date|
      break unless date == expected

      streak += 1
      expected -= 1.day
    end
    streak
  end

  def best_streak(dates)
    return 0 if dates.empty?

    ascending = dates.sort
    best = current = 1
    ascending.each_cons(2) do |a, b|
      if b == a + 1.day
        current += 1
        best = [best, current].max
      else
        current = 1
      end
    end
    best
  end

  def completion_rate(sessions)
    return 0.0 if sessions.empty?

    (sessions.count(&:reached_target?).to_f / sessions.size * 100).round(1)
  end
end
