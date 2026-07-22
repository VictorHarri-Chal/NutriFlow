class WorkoutSession < ApplicationRecord
  include DurationEstimatable

  belongs_to :day

  # Must be declared before the `has_many :workout_sets, dependent: :destroy`
  # below: before_destroy callbacks run in declaration order, so this needs
  # to capture the exercise ids before Rails' own dependent-destroy callback
  # wipes the workout_sets rows.
  before_destroy :capture_pr_recalc_context
  after_destroy :recalculate_prs_after_destroy

  has_many :workout_sets, -> { order(:position) }, dependent: :destroy, inverse_of: :workout_session
  has_many :exercises, through: :workout_sets

  accepts_nested_attributes_for :workout_sets,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs[:exercise_id].blank? }

  MAX_SETS_PER_EXERCISE = 10

  validates :duration_minutes, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validate :must_have_at_least_one_exercise
  validate :max_sets_per_exercise

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
  # When no explicit duration: estimate from logged reps + rest_seconds
  def estimated_calories(weight_kg = nil)
    return calories_burned if calories_burned.present?

    w = (weight_kg.present? && weight_kg > 0) ? weight_kg.to_f : 75.0

    hours = if duration_minutes.present? && duration_minutes > 0
      duration_minutes / 60.0
    else
      estimated_duration_minutes / 60.0
    end

    (weighted_met * rpe_multiplier * w * hours).round
  end

  def total_volume
    workout_sets.sum { |s| (s.weight_kg || 0) * (s.reps || 0) }
  end

  def average_rpe
    return 0.0 if workout_sets.empty?

    workout_sets.map(&:effective_rpe).sum.to_f / workout_sets.size
  end

  def grouped_sets
    if new_record?
      # In-memory: exercises were preloaded via set.exercise = pe.exercise in the controller,
      # or need to be loaded by exercise_id (error re-render case from accepted nested attrs).
      workout_sets.group_by do |s|
        s.exercise || (s.exercise_id.present? ? Exercise.find_by(id: s.exercise_id) : nil)
      end.reject { |exercise, _| exercise.nil? }
    else
      workout_sets.includes(:exercise).group_by(&:exercise)
    end
  end

  private

  def capture_pr_recalc_context
    @pr_recalc_user = user
    @pr_recalc_exercise_ids = workout_sets.pluck(:exercise_id).uniq
  end

  def recalculate_prs_after_destroy
    return if @pr_recalc_exercise_ids.blank?

    PrRecalculator.new(@pr_recalc_user, @pr_recalc_exercise_ids).call
  end

  def must_have_at_least_one_exercise
    active = workout_sets.reject(&:marked_for_destruction?)
    errors.add(:base, I18n.t("activerecord.errors.models.workout_session.at_least_one_exercise")) if active.empty?
  end

  def max_sets_per_exercise
    active = workout_sets.reject(&:marked_for_destruction?)
    too_many = active.group_by(&:exercise_id).values.any? { |sets| sets.size > MAX_SETS_PER_EXERCISE }
    errors.add(:base, I18n.t("activerecord.errors.models.workout_session.too_many_sets_per_exercise")) if too_many
  end

  # Weighted average MET across every body part trained in the session, one
  # set = one weight unit — replaces the old "MET of the first logged
  # exercise" shortcut, which made the result depend on set entry order.
  def weighted_met
    sets_by_body_part = workout_sets.includes(:exercise).group_by { |s| s.exercise&.body_part }
    return DEFAULT_MET if sets_by_body_part.empty?

    total        = sets_by_body_part.sum { |_, sets| sets.size }
    weighted_sum = sets_by_body_part.sum { |bp, sets| (MET_BY_BODY_PART[bp] || DEFAULT_MET) * sets.size }
    weighted_sum / total.to_f
  end

  # rest_seconds is stored once per exercise (on its first set); apply it to
  # every set of that exercise so rest scales with set count — consistent with
  # ProgramDay#duration_estimate_pairs and physically closer to real rest time.
  def duration_estimate_pairs
    rows = workout_sets.pluck(:exercise_id, :reps, :rest_seconds)
    rest_by_exercise = rows.each_with_object({}) do |(exercise_id, _reps, rest), acc|
      acc[exercise_id] = rest if rest.present? && !acc.key?(exercise_id)
    end
    rows.map { |exercise_id, reps, _rest| [reps, rest_by_exercise[exercise_id]] }
  end

  # Scale MET based on RPE (Rate of Perceived Exertion)
  def rpe_multiplier
    case average_rpe
    when 6..7  then 1.00
    when 8..9  then 1.15
    when 10    then 1.30
    else 1.00
    end
  end
end
