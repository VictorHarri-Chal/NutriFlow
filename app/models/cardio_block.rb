class CardioBlock < ApplicationRecord
  belongs_to :cardio_session

  MACHINES = %w[treadmill bike rower ski_erg stairmaster elliptical outdoor_run jump_rope swimming].freeze

  # MET values (Compendium of Physical Activities, Ainsworth et al. 2011)
  # Treadmill & outdoor_run use ACSM metabolic equations (speed + incline).
  # Other machines use Compendium base MET refined by resistance level.
  MET_BY_MACHINE = {
    "bike"        => 7.0,
    "rower"       => 7.5,
    "ski_erg"     => 9.5,
    "stairmaster" => 9.0,
    "elliptical"  => 6.0,
    "jump_rope"   => 12.3,
    "swimming"    => 7.0,
  }.freeze

  # Walking/running boundary: 100 m/min ≈ 6 km/h
  ACSM_WALK_RUN_THRESHOLD_M_MIN = 100.0

  validates :machine,          presence: true, inclusion: { in: MACHINES }
  validates :duration_minutes, presence: true,
                               numericality: { greater_than: 0, only_integer: true }
  validates :speed_kmh,        presence: true, if: -> { shows_speed? }
  validates :speed_kmh,        numericality: { greater_than: 0 }, allow_nil: true
  validates :incline_percent,  presence: true, if: -> { shows_incline? }
  validates :incline_percent,  numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 30 }, allow_nil: true
  validates :resistance_level, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 20 }, allow_nil: true
  validates :distance_km,      numericality: { greater_than: 0 }, allow_nil: true

  before_save :compute_calories

  # ── Public helpers ──────────────────────────────────────────────────────────

  def estimated_calories(weight_kg = 75.0)
    w     = weight_kg.to_f > 0 ? weight_kg.to_f : 75.0
    hours = duration_minutes.to_f / 60.0
    (effective_met * w * hours).round
  end

  def machine_icon
    {
      "treadmill"   => "fa-person-running",
      "bike"        => "fa-bicycle",
      "rower"       => "fa-water",
      "ski_erg"     => "fa-snowflake",
      "stairmaster" => "fa-stairs",
      "elliptical"  => "fa-circle-dot",
      "outdoor_run" => "fa-person-running",
      "jump_rope"   => "fa-bolt",
      "swimming"    => "fa-person-swimming",
    }.fetch(machine, "fa-heart-pulse")
  end

  # Which extra param fields are relevant for this machine
  def shows_speed?      = machine.in?(%w[treadmill outdoor_run])
  def shows_incline?    = machine == "treadmill"
  def shows_resistance? = machine.in?(%w[bike elliptical rower ski_erg stairmaster])
  def shows_distance?   = machine.in?(%w[outdoor_run swimming])

  private

  def effective_met
    case machine
    when "treadmill"   then acsm_met(grade: incline_percent.to_f / 100.0)
    when "outdoor_run" then acsm_met(grade: 0.0)
    else
      base = MET_BY_MACHINE.fetch(machine, 7.0)
      # Resistance scaling: level 10 = neutral; ±2 % per level
      base *= (1.0 + (resistance_level - 10) * 0.02) if shows_resistance? && resistance_level.present?
      base.round(2)
    end
  end

  # ACSM metabolic equations for treadmill/running (ACSM's Guidelines, 11th ed.)
  # Walking  (<100 m/min): VO2_net = 0.1×S + 1.8×S×G
  # Running  (≥100 m/min): VO2_net = 0.2×S + 0.9×S×G
  # Net MET = VO2_net / 3.5  (active calories, resting already excluded)
  # Falls back to Compendium speed-bracket when speed is unknown.
  def acsm_met(grade: 0.0)
    s = speed_kmh.present? ? speed_kmh.to_f * 1000.0 / 60.0 : default_speed_m_min

    net_vo2 = if s < ACSM_WALK_RUN_THRESHOLD_M_MIN
      0.1 * s + 1.8 * s * grade   # walking
    else
      0.2 * s + 0.9 * s * grade   # running
    end

    (net_vo2 / 3.5).round(2)
  end

  # Fallback speed when user didn't enter one (moderate pace)
  def default_speed_m_min
    machine == "treadmill" ? 66.67 : 150.0  # 4 km/h walk | 9 km/h run
  end

  def compute_calories
    weight_kg = cardio_session&.day&.user&.profile&.weight&.to_f || 75.0
    self.calories_burned = estimated_calories(weight_kg)
  end
end
