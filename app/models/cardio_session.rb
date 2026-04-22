class CardioSession < ApplicationRecord
  belongs_to :day, inverse_of: :cardio_sessions
  has_many :cardio_blocks, -> { order(:position) }, dependent: :destroy, inverse_of: :cardio_session

  accepts_nested_attributes_for :cardio_blocks,
    allow_destroy: true

  validate :must_have_at_least_one_block

  delegate :user, to: :day

  def total_calories
    cardio_blocks.sum { |b| b.calories_burned.to_i }
  end

  def total_duration
    cardio_blocks.sum { |b| b.duration_minutes.to_i }
  end

  private

  def must_have_at_least_one_block
    active = cardio_blocks.reject(&:marked_for_destruction?)
    errors.add(:base, I18n.t("activerecord.errors.models.cardio_session.at_least_one_block")) if active.empty?
  end
end
