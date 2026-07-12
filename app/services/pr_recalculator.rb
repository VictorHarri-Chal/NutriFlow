# frozen_string_literal: true

# Recomputes is_pr for every weighted set of the given exercises, for one
# user, in true chronological order (day date, then session, then set
# position) — not "all other sessions regardless of date" like the old
# WorkoutSession#mark_prs!. Backdating a heavier set, editing an old set's
# weight, or deleting the session that held the record all correctly ripple
# through to every set logged since, because the whole history is replayed
# from scratch each time.
#
# The first set ever logged for an exercise is never a PR (nothing to beat
# yet) — a set is a PR only once it strictly beats the best weight logged
# before it for that exercise.
#
# Bodyweight-only sets (no weight_kg, reps-only) are excluded entirely —
# there is no rep-based PR concept yet. Out of scope by design, not a bug.
class PrRecalculator
  # Recomputes every exercise the user has ever logged a weighted set for —
  # used for one-off full backfills (data migration, seeds), not per-request.
  def self.recompute_all_for(user)
    exercise_ids = WorkoutSet
      .joins(workout_session: :day)
      .where(days: { user_id: user.id })
      .distinct
      .pluck(:exercise_id)

    new(user, exercise_ids).call
  end

  def initialize(user, exercise_ids)
    @user = user
    @exercise_ids = Array(exercise_ids).compact.uniq
  end

  def call
    return if @exercise_ids.empty?

    rows = WorkoutSet
      .joins(workout_session: :day)
      .where(exercise_id: @exercise_ids, days: { user_id: @user.id })
      .where.not(weight_kg: nil)
      .order("days.date ASC, workout_sets.workout_session_id ASC, workout_sets.position ASC")
      .pluck(:id, :exercise_id, :weight_kg, :is_pr)

    running_max = Hash.new(0.0)
    to_flag = []
    to_unflag = []

    rows.each do |id, exercise_id, weight_kg, was_pr|
      weight = weight_kg.to_f
      max_so_far = running_max[exercise_id]
      is_pr = max_so_far > 0 && weight > max_so_far
      running_max[exercise_id] = weight if weight > max_so_far

      to_flag << id if is_pr && !was_pr
      to_unflag << id if !is_pr && was_pr
    end

    ActiveRecord::Base.transaction do
      WorkoutSet.where(id: to_flag).update_all(is_pr: true) if to_flag.any?
      WorkoutSet.where(id: to_unflag).update_all(is_pr: false) if to_unflag.any?
    end
  end
end
