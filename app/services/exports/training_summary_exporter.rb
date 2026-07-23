module Exports
  # One sheet, three stacked tables: aggregate totals, recent PRs, top
  # estimated 1RMs. The Brzycki 1RM formula and PR-recency logic mirror
  # StatisticsController's private methods (duplicated, not shared — those
  # are controller-private and out of scope to refactor here).
  class TrainingSummaryExporter
    def initialize(user:, period: nil)
      @user = user
      @period = period
    end

    def sheets
      sets = scoped_sets

      summary_table = {
        title: nil,
        headers: ["Nb séances musculation", "Volume total musculation (kg)", "Nb séances cardio", "Distance cardio totale (km)", "Calories cardio totales"],
        rows: [[
          scoped_sessions.size,
          sets.sum { |s| s.weight_kg.to_f * s.reps.to_i }.round,
          scoped_cardio_blocks.map(&:cardio_session_id).uniq.size,
          total_cardio_distance,
          scoped_cardio_blocks.sum { |b| b.calories_burned.to_i }
        ]]
      }

      prs_table = {
        title: "PR récents",
        headers: ["Date", "Exercice", "Poids (kg)", "Reps"],
        rows: recent_prs(sets).map { |s| [s.workout_session.day.date, exercise_name(s.exercise), s.weight_kg, s.reps] }
      }

      one_rms_table = {
        title: "Top 1RM estimés",
        headers: ["Exercice", "1RM estimé (kg)"],
        rows: top_estimated_one_rms(sets)
      }

      [{ name: "Résumé - Entraînement", tables: [summary_table, prs_table, one_rms_table] }]
    end

    private

    def scoped_sessions
      @scoped_sessions ||= begin
        scope = WorkoutSession.joins(:day).where(days: { user_id: @user.id }).includes(:day, workout_sets: :exercise)
        range = @period&.range
        (range ? scope.where(days: { date: range }) : scope).to_a
      end
    end

    def scoped_sets
      @scoped_sets ||= scoped_sessions.flat_map(&:workout_sets)
    end

    def scoped_cardio_blocks
      @scoped_cardio_blocks ||= begin
        scope = CardioBlock.joins(cardio_session: :day).where(days: { user_id: @user.id }).includes(cardio_session: :day)
        range = @period&.range
        (range ? scope.where(days: { date: range }) : scope).to_a
      end
    end

    def total_cardio_distance
      running_machines = %w[treadmill outdoor_run]
      scoped_cardio_blocks.sum do |b|
        if b.distance_km.present?
          b.distance_km.to_f
        elsif running_machines.include?(b.machine) && b.speed_kmh.present?
          b.speed_kmh.to_f * b.duration_minutes.to_f / 60.0
        else
          0
        end
      end.round(1)
    end

    def recent_prs(sets)
      sets.select(&:is_pr).sort_by { |ws| ws.workout_session.day.date }.last(5).reverse
    end

    def top_estimated_one_rms(sets, top: 3)
      one_rm_by_exercise = {}
      sets.each do |ws|
        orm = estimated_one_rep_max(ws.weight_kg, ws.reps)
        next if orm.nil?

        one_rm_by_exercise[ws.exercise_id] = [one_rm_by_exercise[ws.exercise_id] || 0.0, orm].max
      end

      exercises = Exercise.where(id: one_rm_by_exercise.keys).index_by(&:id)
      one_rm_by_exercise.sort_by { |_, v| -v }.first(top).map { |eid, orm| [exercise_name(exercises[eid]), orm] }
    end

    # Brzycki formula, valid for reps 1-10 only — same restriction as StatisticsController.
    def estimated_one_rep_max(weight_kg, reps)
      return nil unless weight_kg.present? && reps.present? && reps.between?(1, 10) && weight_kg.to_f > 0

      (weight_kg.to_f * 36.0 / (37.0 - reps.to_f)).round(1)
    end

    def exercise_name(exercise)
      exercise&.name_fr.presence || exercise&.name
    end
  end
end
