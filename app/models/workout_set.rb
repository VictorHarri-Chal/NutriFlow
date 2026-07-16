class WorkoutSet < ApplicationRecord
  include RpeSetType

  belongs_to :workout_session
  belongs_to :exercise

  validates :exercise, presence: true
  validates :reps, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :weight_kg, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :exercise_accessible_to_user

  private

  def exercise_accessible_to_user
    return unless exercise && workout_session&.day

    errors.add(:exercise, :invalid) unless Exercise.accessible_to(workout_session.day.user).exists?(exercise.id)
  end
end
