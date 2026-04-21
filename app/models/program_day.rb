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
end
