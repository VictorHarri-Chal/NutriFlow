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
      new_pe = target_day.program_exercises.create!(
        exercise_id:  pe.exercise_id,
        rest_seconds: pe.rest_seconds,
        notes:        pe.notes,
        position:     pe.position
      )
      pe.program_exercise_sets.order(:position).each do |set|
        new_pe.program_exercise_sets.create!(
          position:      set.position,
          reps_target:   set.reps_target,
          weight_target: set.weight_target,
          rpe:           set.rpe,
          set_types:     set.set_types
        )
      end
    end
  end
end
