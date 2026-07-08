class ProgramDay < ApplicationRecord
  belongs_to :workout_program
  has_many :program_exercises, -> { order(:position) }, dependent: :destroy, inverse_of: :program_day

  validates :day_of_week, presence: true,
                          numericality: { in: 0..6, only_integer: true },
                          uniqueness: { scope: :workout_program_id }

  def rest_day?
    name.blank?
  end

  def day_name
    I18n.t("views.workout_programs.day_names.#{WorkoutProgram::DAY_KEYS[day_of_week]}")
  end

  def day_abbr
    I18n.t("views.workout_programs.day_abbrs.#{WorkoutProgram::DAY_KEYS[day_of_week]}")
  end

  def copy_exercises_to!(target_day)
    program_exercises.order(:position).each do |pe|
      target_day.program_exercises.create!(
        exercise_id:   pe.exercise_id,
        sets:          pe.sets,
        reps_target:   pe.reps_target,
        weight_target: pe.weight_target,
        rest_seconds:  pe.rest_seconds,
        notes:         pe.notes,
        position:      pe.position
      )
    end
  end
end
