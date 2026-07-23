module DurationEstimatable
  extend ActiveSupport::Concern

  SECONDS_PER_REP = 3
  MINIMUM_MINUTES = 1

  # Plausible session length from logged reps and rest — a rep takes roughly
  # the same time regardless of exercise, so this is far more accurate than a
  # flat per-set estimate. Each including model provides duration_estimate_pairs,
  # an array of [reps, rest_seconds] pairs (either value may be nil).
  def estimated_duration_minutes
    total_seconds = duration_estimate_pairs.sum { |reps, rest_seconds| reps.to_i * SECONDS_PER_REP + rest_seconds.to_i }
    [(total_seconds / 60.0).round, MINIMUM_MINUTES].max
  end
end
