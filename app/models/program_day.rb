class ProgramDay < ApplicationRecord
  include DurationEstimatable

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
      next if pe.program_exercise_sets.empty?

      new_pe = target_day.program_exercises.build(
        exercise_id:  pe.exercise_id,
        rest_seconds: pe.rest_seconds,
        notes:        pe.notes,
        position:     pe.position
      )
      pe.program_exercise_sets.each do |set|
        new_pe.program_exercise_sets.build(
          position:      set.position,
          reps_target:   set.reps_target,
          weight_target: set.weight_target,
          rpe:           set.rpe,
          set_types:     set.set_types
        )
      end
      new_pe.save!
    end
  end

  def duration_estimate_pairs
    ProgramExerciseSet.joins(:program_exercise)
                       .where(program_exercises: { program_day_id: id })
                       .pluck(:reps_target, "program_exercises.rest_seconds")
  end
end
