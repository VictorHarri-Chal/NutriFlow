json.id         @program.id
json.name       @program.name
json.split_type @program.split_type
json.is_active  @program.is_active

json.program_days @program.program_days.includes(program_exercises: [:exercise, :program_exercise_sets]).order(:day_of_week) do |pd|
  json.id               pd.id
  json.day_of_week      pd.day_of_week
  json.name             pd.name
  json.duration_minutes pd.duration_minutes
  json.notes            pd.notes

  json.program_exercises pd.program_exercises.sort_by(&:position) do |pe|
    json.id            pe.id
    json.exercise_id   pe.exercise_id
    json.exercise_name pe.exercise&.name
    json.rest_seconds  pe.rest_seconds
    json.position      pe.position
    json.notes         pe.notes

    json.sets pe.program_exercise_sets.sort_by(&:position) do |s|
      json.id            s.id
      json.position      s.position
      json.reps_target   s.reps_target
      json.weight_target s.weight_target&.to_f
      json.rpe           s.rpe
      json.set_types     s.set_types
    end
  end
end
