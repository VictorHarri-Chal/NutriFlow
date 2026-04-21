class ProgramExercise < ApplicationRecord
  belongs_to :program_day
  belongs_to :exercise

  validates :sets,        presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :reps_target, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :weight_target, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rest_seconds,  numericality: { greater_than: 0, only_integer: true }, allow_nil: true

  before_create :set_position

  def label
    base = "#{sets}×#{reps_target}"
    weight_target.present? && weight_target > 0 ? "#{base} @ #{weight_target}kg" : base
  end

  private

  def set_position
    self.position = (program_day.program_exercises.maximum(:position) || -1) + 1
  end
end
