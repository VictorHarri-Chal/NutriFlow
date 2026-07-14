class ProgramExercise < ApplicationRecord
  belongs_to :program_day
  belongs_to :exercise
  has_many :program_exercise_sets, -> { order(:position) },
           inverse_of: :program_exercise, dependent: :destroy
  accepts_nested_attributes_for :program_exercise_sets, allow_destroy: true

  validates :rest_seconds, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

  before_create :set_position

  private

  def set_position
    self.position = (program_day.program_exercises.maximum(:position) || -1) + 1
  end
end
