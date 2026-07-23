module Exports
  class StrengthTrainingExporter
    def initialize(user:, period: nil)
      @user = user
      @period = period
    end

    def sheets
      [sessions_sheet, sets_sheet]
    end

    private

    def sessions
      @sessions ||= scoped_sessions.to_a
    end

    def scoped_sessions
      scope = WorkoutSession.joins(:day)
                             .where(days: { user_id: @user.id })
                             .includes(:day, workout_sets: :exercise)
                             .order("days.date")
      range = @period&.range
      range ? scope.where(days: { date: range }) : scope
    end

    def sessions_sheet
      weight = @user.profile&.weight&.to_f
      headers = ["Date", "Durée (min)", "Calories brûlées"]
      rows = sessions.map { |s| [s.day.date, s.duration_minutes, s.estimated_calories(weight)] }
      Exports::Sheet.simple(name: "Musculation - Séances", headers: headers, rows: rows)
    end

    def sets_sheet
      headers = ["Date", "Exercice", "N° série", "Reps", "Poids (kg)", "RPE", "Type de série", "PR"]
      rows = sessions.flat_map do |session|
        session.workout_sets.map.with_index(1) do |set, index|
          [
            session.day.date, exercise_name(set.exercise), index, set.reps, set.weight_kg,
            set.effective_rpe, set.set_types.join(", "), set.is_pr ? "Oui" : "Non"
          ]
        end
      end
      Exports::Sheet.simple(name: "Musculation - Séries", headers: headers, rows: rows)
    end

    def exercise_name(exercise)
      exercise&.name_fr.presence || exercise&.name
    end
  end
end
