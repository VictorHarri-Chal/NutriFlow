class DataExport < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  STATUSES = %w[pending processing completed failed].freeze
  # Kept per user; older ones are pruned (their R2 blob goes with them) so
  # generated files don't accumulate.
  RETENTION_PER_USER = 5

  validates :status, inclusion: { in: STATUSES }

  scope :recent,      -> { order(created_at: :desc) }
  scope :finished,    -> { where(status: %w[completed failed]) }
  scope :in_progress, -> { where(status: %w[pending processing]) }

  def period
    Exports::Period.new(kind: period_kind, date_from: date_from, date_to: date_to)
  end

  def completed? = status == "completed"
  def failed?    = status == "failed"
  def in_progress? = status.in?(%w[pending processing])
end
