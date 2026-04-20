class WorkoutSession < ApplicationRecord
  belongs_to :day
  has_many :workout_sets, -> { order(:position) }, dependent: :destroy, inverse_of: :workout_session
  has_many :exercises, through: :workout_sets

  accepts_nested_attributes_for :workout_sets,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs[:weight_kg].blank? && attrs[:reps].blank? }

  validates :rpe, numericality: { in: 1..10, only_integer: true }, allow_nil: true
  validates :duration_minutes, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validate :must_have_at_least_one_exercise

  delegate :user, to: :day

  # MET values from Compendium of Physical Activities (Ainsworth et al., 2011)
  # Code 02030 – resistance/weight training, moderate effort: MET 3.5
  # Values adjusted downward to account for rest-period proportion (~50% of session time)
  MET_BY_BODY_PART = {
    "back"        => 3.5,
    "chest"       => 3.5,
    "upper legs"  => 4.0,
    "lower legs"  => 3.0,
    "shoulders"   => 3.0,
    "upper arms"  => 2.5,
    "lower arms"  => 2.5,
    "waist"       => 3.0,
    "cardio"      => 6.5,
    "neck"        => 2.5,
  }.freeze

  DEFAULT_MET = 3.5

  # Formula: MET × weight_kg × hours  (Harris-Benedict / Compendium standard)
  # When no explicit duration: estimate 3 min per set (work + rest), min 10 min
  def estimated_calories(weight_kg = nil)
    return calories_burned if calories_burned.present?

    w = (weight_kg.present? && weight_kg > 0) ? weight_kg.to_f : 75.0

    hours = if duration_minutes.present? && duration_minutes > 0
      duration_minutes / 60.0
    else
      [workout_sets.size * 3, 10].max / 60.0
    end

    (primary_body_part_met * rpe_multiplier * w * hours).round
  end

  def total_volume
    workout_sets.sum { |s| (s.weight_kg || 0) * (s.reps || 0) }
  end

  def grouped_sets
    workout_sets.includes(:exercise).group_by(&:exercise)
  end

  private

  def must_have_at_least_one_exercise
    active = workout_sets.reject(&:marked_for_destruction?)
    errors.add(:base, I18n.t("activerecord.errors.models.workout_session.at_least_one_exercise")) if active.empty?
  end

  def primary_body_part_met
    body_part = workout_sets.includes(:exercise).map { |s| s.exercise&.body_part }.compact.first
    MET_BY_BODY_PART[body_part] || DEFAULT_MET
  end

  # Scale MET based on RPE (Rate of Perceived Exertion)
  def rpe_multiplier
    case rpe
    when 1..3  then 0.70
    when 4..5  then 0.85
    when 6..7  then 1.00
    when 8..9  then 1.15
    when 10    then 1.30
    else 1.00
    end
  end
end
