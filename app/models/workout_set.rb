class WorkoutSet < ApplicationRecord
  belongs_to :workout_session
  belongs_to :exercise

  validates :exercise, presence: true
  validates :reps, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :weight_kg, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
