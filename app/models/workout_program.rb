class WorkoutProgram < ApplicationRecord
  SPLIT_TYPES = %w[ppl upper_lower fullbody push_pull bro_split custom].freeze
  DAY_KEYS    = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

  belongs_to :user
  has_many :program_days, -> { order(:day_of_week) }, dependent: :destroy, inverse_of: :workout_program

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :split_type, presence: true, inclusion: { in: SPLIT_TYPES }

  # Ensure only one active program per user
  before_save :deactivate_others, if: -> { is_active? && is_active_changed? }

  # Auto-create 7 ProgramDays on creation
  after_create :create_default_days

  scope :active, -> { where(is_active: true) }

  def activate!
    update!(is_active: true)
  end

  # Aggregates every ProgramExercise's Exercise#tension_profile across all
  # ProgramDays, grouped by body_part. Relies on program_days (and its nested
  # program_exercises: :exercise) already being eager-loaded by the caller.
  # Never queries directly, to avoid N+1 on the program show page.
  def tension_balance
    program_exercises = program_days.flat_map(&:program_exercises).select { |pe| pe.exercise.body_part.present? }

    program_exercises.group_by { |pe| pe.exercise.body_part }.transform_values do |pes|
      pes.group_by { |pe| pe.exercise.tension_profile }.transform_values(&:size)
    end
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
