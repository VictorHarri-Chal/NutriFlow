class ProgramExerciseSet < ApplicationRecord
  include RpeSetType

  belongs_to :program_exercise

  validates :reps_target, presence: true,
                          numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :weight_target, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  before_create :set_position

  def bodyweight?
    weight_target.blank? || weight_target.zero?
  end

  private

  def set_position
    self.position = (program_exercise.program_exercise_sets.maximum(:position) || -1) + 1
  end
end
