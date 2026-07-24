module Exports
  # Not date-scoped: programs are reusable templates, not a log. Two sheets kept
  # readable top-to-bottom rather than four normalized tables to cross-reference:
  # a short overview, then one flat "séances" table where each row is a target
  # set with its program / day / exercise repeated inline.
  class WorkoutProgramsExporter
    def initialize(user:, period: nil)
      @user = user
    end

    def sheets
      [overview_sheet, detail_sheet]
    end

    private

    def programs
      @programs ||= @user.workout_programs
                          .includes(program_days: { program_exercises: [:exercise, :program_exercise_sets] })
                          .to_a
    end

    def overview_sheet
      headers = ["Nom", "Split", "Actif"]
      rows = programs.map { |p| [p.name, I18n.t("views.workout_programs.split_types.#{p.split_type}"), p.is_active? ? "Oui" : "Non"] }
      Exports::Sheet.simple(name: "Programmes", headers: headers, rows: rows)
    end

    def detail_sheet
      headers = [
        "Programme", "Jour", "Repos", "Exercice", "Repos (s)", "Notes",
        "N° série", "Reps cible", "Poids cible (kg)", "RPE", "Type de série"
      ]
      rows = programs.flat_map { |p| program_rows(p) }
      Exports::Sheet.simple(name: "Programmes - Séances", headers: headers, rows: rows)
    end

    def program_rows(program)
      program.program_days.flat_map do |day|
        if day.rest_day?
          [[program.name, day.day_name, "Oui", nil, nil, nil, nil, nil, nil, nil, nil]]
        elsif day.program_exercises.empty?
          [[program.name, day.day_name, "Non", nil, nil, nil, nil, nil, nil, nil, nil]]
        else
          day.program_exercises.flat_map { |pe| exercise_rows(program, day, pe) }
        end
      end
    end

    def exercise_rows(program, day, program_exercise)
      exercise = exercise_name(program_exercise.exercise)
      sets = program_exercise.program_exercise_sets
      if sets.empty?
        [[program.name, day.day_name, "Non", exercise, program_exercise.rest_seconds, program_exercise.notes, nil, nil, nil, nil, nil]]
      else
        sets.map.with_index(1) do |set, index|
          [
            program.name, day.day_name, "Non", exercise, program_exercise.rest_seconds, program_exercise.notes,
            index, set.reps_target, set.weight_target, set.rpe, set.set_types.join(", ")
          ]
        end
      end
    end

    def exercise_name(exercise)
      exercise&.name_fr.presence || exercise&.name
    end
  end
end
