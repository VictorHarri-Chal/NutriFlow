class ProgramExerciseSet < ApplicationRecord
  belongs_to :program_exercise

  attribute :set_types, default: -> { ["working"] }

  SET_TYPES = %w[warmup working failure dropset].freeze
  DISPLAY_PRIORITY = %w[failure dropset warmup].freeze

  validates :reps_target, presence: true,
                          numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :weight_target, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rpe, numericality: { only_integer: true, greater_than_or_equal_to: 6, less_than_or_equal_to: 10 },
                  allow_nil: true
  validate :set_types_must_be_known
  before_validation :strip_blank_set_types

  DEFAULT_RPE_BY_TYPE = { "failure" => 10, "dropset" => 9, "warmup" => 5 }.freeze

  def effective_rpe
    return rpe if rpe.present?
    return DEFAULT_RPE_BY_TYPE["failure"] if set_types.include?("failure")
    return DEFAULT_RPE_BY_TYPE["dropset"] if set_types.include?("dropset")
    return DEFAULT_RPE_BY_TYPE["warmup"]  if set_types == ["warmup"]

    7 # série de travail lambda
  end

  def bodyweight?
    weight_target.blank? || weight_target.zero?
  end

  def dominant_type
    DISPLAY_PRIORITY.find { |type| set_types.include?(type) }
  end

  private

  def set_types_must_be_known
    invalid = Array(set_types) - SET_TYPES
    errors.add(:set_types, :inclusion) if invalid.any?
  end

  def strip_blank_set_types
    self.set_types = Array(set_types).reject(&:blank?)
  end
end
