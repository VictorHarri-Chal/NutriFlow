class WeightEntry < ApplicationRecord
  belongs_to :user

  validates :date,      presence: true, uniqueness: { scope: :user_id }
  validates :weight_kg, presence: true,
                        numericality: { greater_than: 20, less_than: 400 }
  validate  :date_not_in_future

  scope :ordered,    -> { order(:date) }
  scope :for_period, ->(from, to) { ordered.where(date: from..to) }

  private

  def date_not_in_future
    return unless date.present? && date > Date.today

    errors.add(:date, :invalid)
  end
end
