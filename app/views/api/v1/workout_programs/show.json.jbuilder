json.id         @program.id
json.name       @program.name
json.split_type @program.split_type
json.is_active  @program.is_active

json.program_days @program.program_days.includes(program_exercises: :exercise).order(:day_of_week) do |pd|
  json.id               pd.id
  json.day_of_week      pd.day_of_week
  json.name             pd.name
  json.duration_minutes pd.duration_minutes
  json.notes            pd.notes

  json.program_exercises pd.program_exercises.order(:position) do |pe|
    json.id            pe.id
    json.exercise_id   pe.exercise_id
    json.exercise_name pe.exercise&.name
    json.sets          pe.sets
    json.reps_target   pe.reps_target
    json.weight_target pe.weight_target
    json.rest_seconds  pe.rest_seconds
    json.position      pe.position
    json.notes         pe.notes
  end
end
