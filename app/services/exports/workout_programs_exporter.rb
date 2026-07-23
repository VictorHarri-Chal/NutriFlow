module Exports
  # Not date-scoped: programs are reusable templates, not a log.
  class WorkoutProgramsExporter
    def initialize(user:, period: nil)
      @user = user
    end

    def sheets
      [programs_sheet, days_sheet, exercises_sheet, sets_sheet]
    end

    private

    def programs
      @programs ||= @user.workout_programs
                          .includes(program_days: { program_exercises: [:exercise, :program_exercise_sets] })
                          .to_a
    end

    def programs_sheet
      headers = ["Nom", "Split", "Actif"]
      rows = programs.map { |p| [p.name, I18n.t("views.workout_programs.split_types.#{p.split_type}"), p.is_active? ? "Oui" : "Non"] }
      Exports::Sheet.simple(name: "Programmes", headers: headers, rows: rows)
    end

    def days_sheet
      headers = ["Programme", "Jour", "Repos"]
      rows = programs.flat_map do |p|
        p.program_days.map { |pd| [p.name, pd.day_name, pd.rest_day? ? "Oui" : "Non"] }
      end
      Exports::Sheet.simple(name: "Programmes - Jours", headers: headers, rows: rows)
    end

    def exercises_sheet
      headers = ["Programme", "Jour", "Exercice", "Repos (s)", "Notes"]
      rows = programs.flat_map do |p|
        p.program_days.flat_map do |pd|
          pd.program_exercises.map { |pe| [p.name, pd.day_name, exercise_name(pe.exercise), pe.rest_seconds, pe.notes] }
        end
      end
      Exports::Sheet.simple(name: "Programmes - Exercices", headers: headers, rows: rows)
    end

    def sets_sheet
      headers = ["Programme", "Jour", "Exercice", "N° série", "Reps cible", "Poids cible (kg)", "RPE", "Type de série"]
      rows = programs.flat_map do |p|
        p.program_days.flat_map do |pd|
          pd.program_exercises.flat_map do |pe|
            pe.program_exercise_sets.map.with_index(1) do |set, index|
              [p.name, pd.day_name, exercise_name(pe.exercise), index, set.reps_target, set.weight_target, set.rpe, set.set_types.join(", ")]
            end
          end
        end
      end
      Exports::Sheet.simple(name: "Programmes - Séries cibles", headers: headers, rows: rows)
    end

    def exercise_name(exercise)
      exercise&.name_fr.presence || exercise&.name
    end
  end
end
