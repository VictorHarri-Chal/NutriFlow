class FastingSession < ApplicationRecord
  extend Enumerize
  belongs_to :user

  PROTOCOLS = %i[sixteen_eight eighteen_six omad circadian_12_12].freeze

  # Durée cible en heures par protocole — pas de colonne dédiée en v1
  # (aucun protocole personnalisable pour l'instant).
  TARGET_HOURS = {
    sixteen_eight:   16,
    eighteen_six:    18,
    omad:            23,
    circadian_12_12: 12
  }.freeze

  enumerize :protocol, in: PROTOCOLS, default: :sixteen_eight

  validates :started_at, presence: true
  validate  :only_one_active_session_per_user, on: :create

  scope :active,    -> { where(ended_at: nil) }
  scope :completed, -> { where.not(ended_at: nil) }
  scope :ordered,   -> { order(started_at: :desc) }
  scope :overlapping, ->(range) {
    where("started_at < ? AND (ended_at IS NULL OR ended_at > ?)", range.end, range.begin)
  }

  def active?
    ended_at.nil?
  end

  def target_duration_hours
    TARGET_HOURS.fetch(protocol.to_sym)
  end

  def elapsed_hours
    ((ended_at || Time.current) - started_at) / 3600.0
  end

  def progress_percentage
    [(elapsed_hours / target_duration_hours * 100), 100].min.round(1)
  end

  def expected_end_at
    started_at + target_duration_hours.hours
  end

  def reached_target?
    elapsed_hours >= target_duration_hours
  end

  def remaining_hours
    [target_duration_hours - elapsed_hours, 0].max
  end

  def finish!
    update!(ended_at: Time.current)
  end

  private

  def only_one_active_session_per_user
    return unless active?
    return unless user.fasting_sessions.active.exists?

    errors.add(:base, :active_session_already_exists)
  end
end
