module RpeSetType
  extend ActiveSupport::Concern

  SET_TYPES = %w[warmup working failure dropset].freeze
  DISPLAY_PRIORITY = %w[failure dropset warmup].freeze
  DEFAULT_RPE_BY_TYPE = { "failure" => 10, "dropset" => 9, "warmup" => 5 }.freeze
  MIN_RPE = 6
  MAX_RPE = 10

  included do
    validates :rpe, numericality: { only_integer: true, greater_than_or_equal_to: MIN_RPE, less_than_or_equal_to: MAX_RPE },
                    allow_nil: true
    validate :set_types_must_be_known
    before_validation :strip_blank_set_types
  end

  def effective_rpe
    rpe.presence || DEFAULT_RPE_BY_TYPE.fetch(dominant_type, 7)
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
