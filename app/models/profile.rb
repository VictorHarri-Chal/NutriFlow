class Profile < ApplicationRecord
  extend Enumerize

  GENDERS = %i[male female other].freeze
  GOALS   = %i[weight_loss maintenance muscle_gain].freeze

  JOB_ACTIVITY_LEVELS = %i[desk_job light_activity standing_job physical_job].freeze

  # Fixed NEAT offset per job type (kcal/day), excluding steps and workouts
  # Based on Ainsworth Compendium + standard NEAT estimation literature
  JOB_NEAT_KCAL = {
    desk_job:       150,
    light_activity: 300,
    standing_job:   500,
    physical_job:   800
  }.freeze

  # kcal burned per step, normalised to 70 kg reference body weight
  # Derived from MET 3.5 (walking) × 0.04 kcal/step base
  KCAL_PER_STEP_AT_70KG = 0.04

  # Goal multipliers applied to TDEE
  GOAL_MULTIPLIERS = {
    weight_loss:  0.85,  # −15 % deficit
    maintenance:  1.0,
    muscle_gain:  1.10   # +10 % surplus (lean bulk)
  }.freeze

  enumerize :gender,             in: GENDERS,             predicates: true, scope: true
  enumerize :job_activity_level, in: JOB_ACTIVITY_LEVELS, predicates: true, scope: true
  enumerize :goal,               in: GOALS,               predicates: true, scope: true

  belongs_to :user

  before_validation :set_default_steps

  validates :name,               length: { maximum: 30 }
  validates :weight,             numericality: { greater_than: 0, less_than: 500 }, allow_blank: true
  validates :height,             numericality: { greater_than: 0, less_than: 300 }, allow_blank: true
  validates :age,                numericality: { greater_than: 0, less_than: 120 }, allow_blank: true
  validates :goal_weight,        numericality: { greater_than: 20, less_than: 400 }, allow_blank: true
  validates :water_goal_ml,      numericality: { greater_than: 0, less_than: 10_000 }, allow_blank: true
  validates :default_daily_steps, numericality: { greater_than_or_equal_to: 0, less_than: 100_000 }, allow_blank: true

  # ── Calorie calculations ───────────────────────────────────────────────────

  # Mifflin-St Jeor BMR (kcal/day at complete rest)
  def bmr
    return nil unless weight.present? && height.present? && age.present?

    @bmr ||= (10 * weight.to_f + 6.25 * height.to_f - 5 * age.to_f + gender_bmr_constant).round
  end

  # NEAT from steps: kcal burned walking, scaled to user's weight
  # Formula: steps × 0.04 × (weight_kg / 70)
  def neat_from_steps(steps_count)
    return 0 unless weight.present? && weight.to_f > 0

    (steps_count.to_i * KCAL_PER_STEP_AT_70KG * (weight.to_f / 70.0)).round
  end

  # Total Daily Energy Expenditure for a given Day record
  # TDEE = BMR + job_neat + steps_neat + workout_kcal
  def tdee(day:)
    return nil unless bmr

    job_neat    = JOB_NEAT_KCAL[job_activity_level.to_sym] || JOB_NEAT_KCAL[:light_activity]
    steps       = day.effective_steps(self)
    steps_kcal  = neat_from_steps(steps)
    workout_kcal = day.workout_calories_total

    bmr + job_neat + steps_kcal + workout_kcal
  end

  # Final calorie target for the day, adjusted for goal
  def daily_calorie_target(day:)
    base = tdee(day: day)
    return nil unless base

    multiplier = GOAL_MULTIPLIERS[goal.to_sym] || 1.0
    (base * multiplier).round
  end

  # TDEE without goal multiplier, using profile's default_daily_steps
  def base_tdee
    return nil unless bmr

    job_neat   = JOB_NEAT_KCAL[job_activity_level.to_sym] || JOB_NEAT_KCAL[:light_activity]
    steps_kcal = neat_from_steps(default_daily_steps || 6_000)
    bmr + job_neat + steps_kcal
  end

  # Goal-adjusted calorie target (used for macro computations)
  def calories_needed_for_goal
    return nil unless (tdee = base_tdee)

    multiplier = GOAL_MULTIPLIERS[goal.to_sym] || 1.0
    (tdee * multiplier).round
  end

  # ── Macro goals ───────────────────────────────────────────────────────────

  def daily_protein_goal
    return nil unless weight.present?
    weight * 2
  end

  def daily_fats_goal
    return nil unless weight.present?
    weight * 1
  end

  def daily_carbs_goal(day: nil)
    calorie_goal = day ? daily_calorie_target(day: day) : calories_needed_for_goal
    return nil unless calorie_goal && weight.present?

    protein_kcal = daily_protein_goal * 4
    fat_kcal     = daily_fats_goal * 9
    remaining    = calorie_goal - protein_kcal - fat_kcal
    return nil if remaining <= 0

    (remaining / 4.0).round
  end

  private

  def set_default_steps
    self.default_daily_steps = 6_000 if default_daily_steps.nil?
  end

  def gender_bmr_constant
    case gender.to_s
    when "female" then -161
    when "male"   then 5
    else               -78   # other: mean of male/female
    end
  end
end
