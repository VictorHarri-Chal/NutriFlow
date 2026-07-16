class ProgramExercise < ApplicationRecord
  belongs_to :program_day
  belongs_to :exercise
  has_many :program_exercise_sets, -> { order(:position) },
           inverse_of: :program_exercise, dependent: :destroy
  accepts_nested_attributes_for :program_exercise_sets, allow_destroy: true

  MAX_SETS = 10

  validates :rest_seconds, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validate :exercise_accessible_to_user
  validate :max_sets_count

  before_create :set_position

  private

  def exercise_accessible_to_user
    return unless exercise && program_day&.workout_program

    errors.add(:exercise, :invalid) unless Exercise.accessible_to(program_day.workout_program.user).exists?(exercise.id)
  end

  def max_sets_count
    active = program_exercise_sets.reject(&:marked_for_destruction?)
    errors.add(:base, I18n.t("activerecord.errors.models.program_exercise.too_many_sets")) if active.size > MAX_SETS
  end

  def set_position
    self.position = (program_day.program_exercises.maximum(:position) || -1) + 1
  end
end
