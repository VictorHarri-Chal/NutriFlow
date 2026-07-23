class Profile < ApplicationRecord
  extend Enumerize

  GENDERS = %i[male female other].freeze
  GOALS   = %i[weight_loss maintain muscle_gain].freeze

  JOB_ACTIVITY_LEVELS = %i[sedentary light_activity standing_job physical_job].freeze

  # Fixed NEAT offset per job type (kcal/day), excluding steps and workouts
  # Based on Ainsworth Compendium + standard NEAT estimation literature
  JOB_NEAT_KCAL = {
    sedentary:      150,
    light_activity: 300,
    standing_job:   500,
    physical_job:   800
  }.freeze

  # Average daily steps already assumed by each job category — used to avoid
  # double-counting the same walking when the user also logs real steps.
  # Independent from JOB_NEAT_KCAL (not derived from it): a literal inverse
  # calculation would give unrealistic thresholds (~20 000 steps for
  # physical_job), making the steps field useless for the most active users.
  JOB_BASELINE_STEPS = {
    desk_job:       4_000,
    light_activity: 6_500,
    standing_job:   9_000,
    physical_job:   12_000
  }.freeze

  # kcal burned per step, normalised to 70 kg reference body weight
  # Derived from MET 3.5 (walking) × 0.04 kcal/step base
  KCAL_PER_STEP_AT_70KG = 0.04

  # kcal per kg of body fat — standard nutrition estimate, used to convert a
  # weekly weight-change rate into a daily calorie delta.
  KCAL_PER_KG = 7700

  # Fallback defaults when TDEE can't be computed yet (incomplete profile).
  # Otherwise, #default_weight_loss_rate / #default_muscle_gain_rate compute
  # a per-user default from ±15%/±10% of TDEE, converted to kg/week.
  FALLBACK_WEIGHT_LOSS_RATE = -0.5
  FALLBACK_MUSCLE_GAIN_RATE = 0.25

  # Allowed input range for goal_rate_kg_per_week. This is a soft guardrail:
  # the recommended sub-range (see goal_rate_estimator_controller.js) is only
  # enforced as a UI warning, not a hard validation limit.
  GOAL_RATE_RANGE = -1.5..1.0

  # Fat target as a share of total calories rather than a flat g/kg amount,
  # so it scales with the calorie goal (deficit vs surplus) instead of
  # dumping every surplus/deficit calorie onto carbs alone. Protein stays
  # g/kg — sports nutrition guidance ties protein need to bodyweight, not
  # calorie intake, precisely so it doesn't drop during a deficit.
  FAT_PERCENT_OF_CALORIES = 0.25

  # Extra water per day based on physical job activity (hors séances sportives)
  # Sources: IoM DRI + TrainingPeaks sweat rate data
  WATER_ACTIVITY_OFFSET_ML = {
    sedentary:      0,
    light_activity: 300,
    standing_job:   500,
    physical_job:   700
  }.freeze

  enumerize :gender,             in: GENDERS,             predicates: true, scope: true
  enumerize :job_activity_level, in: JOB_ACTIVITY_LEVELS, predicates: true, scope: true
  enumerize :goal,               in: GOALS,               predicates: true, scope: true

  belongs_to :user

  before_validation :set_default_steps
  before_validation :set_default_water_goal
  before_validation :default_goal_weight_to_current_weight
  before_validation :sync_goal_with_target_weight

  validates :name,               length: { maximum: 30 }
  validates :name, :date_of_birth, :weight, :height, :gender, presence: true, on: :update
  validates :weight,             numericality: { greater_than: 0, less_than: 500 }, allow_blank: true
  validates :height,             numericality: { greater_than: 0, less_than: 300 }, allow_blank: true
  validate  :date_of_birth_is_plausible
  validates :goal_weight,        presence: true, if: :profile_ready_for_goal?
  validates :goal_weight,        numericality: { greater_than_or_equal_to: 20, less_than_or_equal_to: 400 }, allow_blank: true
  validates :water_goal_ml,      numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 }, allow_blank: true
  validates :default_daily_steps, numericality: { greater_than_or_equal_to: 0, less_than: 100_000 }, allow_blank: true
  validates :goal_rate_kg_per_week, numericality: {
    greater_than_or_equal_to: GOAL_RATE_RANGE.min,
    less_than_or_equal_to:    GOAL_RATE_RANGE.max
  }, if: :profile_ready_for_goal?
  validate :goal_rate_matches_goal_direction, if: :profile_ready_for_goal?

  # ── Hydration ─────────────────────────────────────────────────────────────

  # Estimated daily water need (ml) based on weight, gender and activity level.
  # Formula: 33ml/kg × gender coefficient + job activity offset.
  def computed_water_goal_ml
    return nil unless weight.present? && weight.to_f > 0

    base     = weight.to_f * 33
    gendered = gender.to_s == "female" ? base * 0.9 : base
    offset   = WATER_ACTIVITY_OFFSET_ML[job_activity_level&.to_sym] || 0
    ((gendered + offset) / 50.0).round * 50
  end

  # ── Age ───────────────────────────────────────────────────────────────────

  # Computed from date_of_birth rather than stored as a static integer, so
  # it stays correct as time passes instead of silently going stale.
  def age
    return nil unless date_of_birth.present?

    today = Date.current
    years = today.year - date_of_birth.year
    years -= 1 if today < date_of_birth + years.years
    years
  end

  # ── BMI ───────────────────────────────────────────────────────────────────

  def bmi(weight_kg = nil)
    return nil unless height.present? && height.to_f > 0
    w = weight_kg || self.weight
    return nil unless w.present?
    (w.to_f / ((height.to_f / 100.0)**2)).round(1)
  end

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

  # Kcal from the day's steps beyond the average already assumed by the
  # selected job category — see JOB_BASELINE_STEPS. Never negative: a day
  # below the job's average simply earns zero extra credit, no penalty.
  def steps_neat_kcal(steps_count)
    baseline = JOB_BASELINE_STEPS[job_activity_level&.to_sym] || JOB_BASELINE_STEPS[:light_activity]
    excess   = [steps_count.to_i - baseline, 0].max
    neat_from_steps(excess)
  end

  # Full TDEE decomposition for a given Day record. The only place the
  # formula is implemented — CalendarDataLoader delegates here instead of
  # recomputing it, so the two can never silently drift apart.
  # TDEE = BMR + job_neat + steps_neat (excess over job baseline) + workout_kcal
  def tdee_breakdown(day:)
    return nil unless bmr

    job_neat     = JOB_NEAT_KCAL[job_activity_level.to_sym] || JOB_NEAT_KCAL[:light_activity]
    steps_count  = day.effective_steps(self)
    steps_kcal   = steps_neat_kcal(steps_count)
    workout_kcal = day.workout_calories_total

    {
      bmr:          bmr,
      job_neat:     job_neat,
      steps_kcal:   steps_kcal,
      steps_count:  steps_count,
      steps_custom: day.steps.present?,
      workout_kcal: workout_kcal,
      tdee:         bmr + job_neat + steps_kcal + workout_kcal
    }
  end

  # Total Daily Energy Expenditure for a given Day record
  def tdee(day:)
    tdee_breakdown(day: day)&.fetch(:tdee)
  end

  # Final calorie target for the day, adjusted for goal
  def daily_calorie_target(day:)
    base = tdee(day: day)
    return nil unless base

    base + daily_calorie_delta
  end

  # TDEE without goal multiplier, using profile's default_daily_steps
  def base_tdee
    return nil unless bmr

    job_neat   = JOB_NEAT_KCAL[job_activity_level.to_sym] || JOB_NEAT_KCAL[:light_activity]
    steps_kcal = steps_neat_kcal(default_daily_steps || 6_000)
    bmr + job_neat + steps_kcal
  end

  # Goal-adjusted calorie target (used for macro computations)
  def calories_needed_for_goal
    return nil unless (tdee = base_tdee)

    tdee + daily_calorie_delta
  end

  # Daily kcal delta derived from the weekly rate goal (0 for maintenance,
  # or if no goal is set)
  def daily_calorie_delta
    return 0 unless goal&.weight_loss? || goal&.muscle_gain?

    (goal_rate_kg_per_week.to_f * KCAL_PER_KG / 7.0).round
  end

  # Default weekly rate for the weight-loss goal, personalised to this
  # profile's TDEE (≈ -15% of TDEE converted to kg/week). Falls back to a
  # flat default when TDEE can't be computed yet (incomplete profile).
  def default_weight_loss_rate
    return FALLBACK_WEIGHT_LOSS_RATE unless (tdee = base_tdee)

    (-0.15 * tdee / KCAL_PER_KG.to_f * 7).round(2)
  end

  # Default weekly rate for the muscle-gain goal, personalised to this
  # profile's TDEE (≈ +10% of TDEE converted to kg/week).
  def default_muscle_gain_rate
    return FALLBACK_MUSCLE_GAIN_RATE unless (tdee = base_tdee)

    (0.10 * tdee / KCAL_PER_KG.to_f * 7).round(2)
  end

  # The 3-scenario preview (weight loss / maintenance / muscle gain) shown
  # on the profile page and the daily calorie requirements page. The active
  # goal's real rate is used for its own scenario; the other two fall back
  # to their personalised defaults, purely as a preview. Returns nil if
  # base_tdee can't be computed yet (incomplete profile).
  def calorie_scenarios
    return nil unless (base = base_tdee)

    weight_loss_rate = goal&.weight_loss? ? goal_rate_kg_per_week.to_f : default_weight_loss_rate
    muscle_gain_rate = goal&.muscle_gain? ? goal_rate_kg_per_week.to_f : default_muscle_gain_rate

    {
      maintenance:      base,
      weight_loss_rate: weight_loss_rate,
      muscle_gain_rate: muscle_gain_rate,
      weight_loss:      base + (weight_loss_rate * KCAL_PER_KG / 7.0).round,
      muscle_gain:      base + (muscle_gain_rate * KCAL_PER_KG / 7.0).round
    }
  end

  # Goal direction implied by comparing goal_weight to the current weight:
  # a lower target means weight_loss, a higher one means muscle_gain, an
  # equal one means maintenance. Returns nil if either weight is missing —
  # in that case no direction is implied yet.
  def implied_goal_direction
    return nil unless weight.present? && goal_weight.present?

    if goal_weight < weight
      "weight_loss"
    elsif goal_weight > weight
      "muscle_gain"
    else
      "maintenance"
    end
  end

  # Estimated number of weeks to reach goal_weight at the current rate.
  # Returns nil if data is missing, the rate is zero, or the rate's
  # direction doesn't match the direction needed to reach goal_weight.
  def estimated_weeks_to_goal
    return nil unless weight.present? && goal_weight.present? && goal_rate_kg_per_week.nonzero?

    weight_delta = goal_weight - weight
    return nil if weight_delta.zero?
    return nil unless weight_delta.negative? == goal_rate_kg_per_week.negative?

    (weight_delta.abs / goal_rate_kg_per_week.abs).round
  end

  # ── Macro goals ───────────────────────────────────────────────────────────

  def daily_protein_goal
    return nil unless weight.present?
    weight * 2
  end

  # Percentage of the calorie goal rather than a flat g/kg amount, so it
  # scales with the size of the deficit/surplus — see FAT_PERCENT_OF_CALORIES.
  def daily_fats_goal(day: nil)
    calorie_goal = calorie_goal_for(day)
    return nil unless calorie_goal

    [(calorie_goal * FAT_PERCENT_OF_CALORIES / 9.0).round(1), 0].max
  end

  def daily_carbs_goal(day: nil)
    calorie_goal = calorie_goal_for(day)
    return nil unless calorie_goal && weight.present?

    protein_kcal = daily_protein_goal * 4
    fat_kcal     = daily_fats_goal(day: day) * 9
    remaining    = calorie_goal - protein_kcal - fat_kcal

    [(remaining / 4.0).round, 0].max
  end

  # True when protein + fat targets alone already exceed the calorie goal
  # (a very low calorie target relative to bodyweight) — without this,
  # carbs silently floors at 0 with no indication of why.
  def macro_calories_exceed_goal?(day: nil)
    calorie_goal = calorie_goal_for(day)
    return false unless calorie_goal && weight.present?

    (daily_protein_goal * 4) + (daily_fats_goal(day: day) * 9) > calorie_goal
  end

  # Objectifs hebdomadaires (AJR ANSES × 7) par micronutrient. Aucun des 14
  # nutriments gérés ne dépend du poids ni de l'activité physique (voir l'annexe
  # du spec) — uniquement du sexe, avec la même convention que
  # #gender_bmr_constant pour "other" (moyenne homme/femme).
  def weekly_micronutrient_goals
    Micronutrient::ALL.each_with_object({}) do |entry, acc|
      next if entry.nature == :none

      daily = case gender.to_s
              when "male"   then entry.rda_male
              when "female" then entry.rda_female
              else               (entry.rda_male + entry.rda_female) / 2.0
              end
      acc[entry.key] = (daily * 7).round(2)
    end
  end

  # The whole goal mechanism (target weight, rate, and their personalised
  # defaults) needs a computable BMR — i.e. weight, height and age — to mean
  # anything. Without it, none of these fields are shown in the UI, so none
  # of them should be enforced either.
  def profile_ready_for_goal?
    bmr.present?
  end

  # The mandatory post-signup fields — distinct from #profile_ready_for_goal?,
  # which only cares about BMR inputs and ignores name/gender.
  def onboarding_complete?
    name.present? && date_of_birth.present? && weight.present? && height.present? && gender.present?
  end

  private

  def calorie_goal_for(day)
    day ? daily_calorie_target(day: day) : calories_needed_for_goal
  end

  # Re-syncs to the new job's baseline when the job changes and the user
  # didn't also type an explicit steps value in that same update — otherwise
  # a profile auto-created blank at signup (job defaults to light_activity,
  # see db/schema.rb) would keep light_activity's baseline forever once the
  # user picks their real job on the profile edit form (onboarding itself
  # never collects job_activity_level — see OnboardingController).
  def set_default_steps
    return unless default_daily_steps.blank? || (job_activity_level_changed? && !default_daily_steps_changed?)

    self.default_daily_steps = JOB_BASELINE_STEPS[job_activity_level&.to_sym] ||
                                JOB_BASELINE_STEPS[:light_activity]
  end

  # water_goal_ml is NOT NULL at the DB level — clearing the field in the
  # form casts it to nil, which must never reach the database as-is.
  def set_default_water_goal
    self.water_goal_ml = 2000 if water_goal_ml.nil?
  end

  # goal_weight defaults to the current weight (i.e. "maintain") whenever it
  # hasn't been set yet — otherwise submitting weight/height/date_of_birth
  # alone (e.g. from onboarding, which doesn't collect a target weight) would
  # make the profile "ready for goal" while failing its goal_weight presence
  # validation.
  def default_goal_weight_to_current_weight
    self.goal_weight = weight if goal_weight.blank? && weight.present?
  end

  def date_of_birth_is_plausible
    return if date_of_birth.blank?

    if date_of_birth > Date.current
      errors.add(:date_of_birth, :cannot_be_in_the_future)
    elsif date_of_birth < 120.years.ago.to_date
      errors.add(:date_of_birth, :too_far_in_the_past)
    end
  end

  def goal_rate_matches_goal_direction
    return if goal.blank?

    if goal.weight_loss? && goal_rate_kg_per_week.positive?
      errors.add(:goal_rate_kg_per_week, :must_be_negative_for_weight_loss)
    elsif goal.muscle_gain? && goal_rate_kg_per_week.negative?
      errors.add(:goal_rate_kg_per_week, :must_be_positive_for_muscle_gain)
    end
  end

  # Goal is a derived attribute, not a free user choice: it always tracks
  # the direction implied by comparing goal_weight to weight. This runs
  # before validation so manual tampering (or a stale client value) can
  # never persist an inconsistent goal.
  def sync_goal_with_target_weight
    implied = implied_goal_direction
    self.goal = implied if implied.present?
  end

  def gender_bmr_constant
    case gender.to_s
    when "female" then -161
    when "male"   then 5
    else               -78   # other: mean of male/female
    end
  end
end
