class WorkoutProgram < ApplicationRecord
  belongs_to :user
  has_many :program_days, -> { order(:day_of_week) }, dependent: :destroy, inverse_of: :workout_program

  validates :name, presence: true
  validates :split_type, presence: true, inclusion: { in: %w[ppl upper_lower fullbody push_pull bro_split custom] }

  SPLIT_TYPES = %w[ppl upper_lower fullbody push_pull bro_split custom].freeze

  DAY_KEYS  = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

  # Ensure only one active program per user
  before_save :deactivate_others, if: -> { is_active? && is_active_changed? }

  # Auto-create 7 ProgramDays on creation
  after_create :create_default_days

  scope :active, -> { where(is_active: true) }

  def activate!
    update!(is_active: true)
  end

  private

  def deactivate_others
    user.workout_programs.where.not(id: id).update_all(is_active: false)
  end

  def create_default_days
    7.times do |i|
      program_days.create!(day_of_week: i, name: nil)
    end
  end
end
