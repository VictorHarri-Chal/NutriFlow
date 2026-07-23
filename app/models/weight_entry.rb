class WeightEntry < ApplicationRecord
  belongs_to :user

  validates :date,      presence: true, uniqueness: { scope: :user_id }
  validates :weight_kg, presence: true,
                        numericality: { greater_than_or_equal_to: 20, less_than_or_equal_to: 400 }
  validate  :date_not_in_future

  after_save    :sync_profile_weight
  after_destroy :sync_profile_weight

  scope :ordered,    -> { order(:date) }
  scope :for_period, ->(from, to) { ordered.where(date: from..to) }

  private

  def date_not_in_future
    return unless date.present? && date > Date.today

    errors.add(:date, :invalid)
  end

  # Profile#weight is the single source of truth for every calorie/BMR
  # calculation in the app. Keep it in sync with the most recent (by date,
  # not by save order) weight entry, so logging a new weigh-in updates
  # calorie targets automatically instead of silently going stale.
  #
  # Uses update_column (skips validations/callbacks) because this only ever
  # touches the single `weight` column: running full profile validation here
  # would block the sync whenever an unrelated field (e.g. goal_weight) is
  # blank, silently leaving Profile#weight stale.
  def sync_profile_weight
    latest = user.weight_entries.ordered.last
    return unless latest

    user.profile&.update_column(:weight, latest.weight_kg)
  end
end
