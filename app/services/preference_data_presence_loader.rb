# frozen_string_literal: true

# Determines, for a given user, which preferences have existing related data —
# used by PreferenceToggleComponent to decide whether disabling a preference
# requires a confirmation.
class PreferenceDataPresenceLoader
  def initialize(user)
    @user = user
  end

  def call
    {
      show_workout_section: workout_data?,
      show_cardio_section:  cardio_data?,
      show_water_tracking:  water_data?,
      show_weight_tracking: weight_data?,
      show_day_note:        day_note_data?,
      show_body_measurements: body_measurement_data?,
      show_fasting_tracking: fasting_data?
    }
  end

  private

  attr_reader :user

  def fasting_data?
    user.fasting_sessions.exists?
  end

  def workout_data?
    WorkoutSession.joins(:day).where(days: { user_id: user.id }).exists?
  end

  def cardio_data?
    CardioSession.joins(:day).where(days: { user_id: user.id }).exists?
  end

  def water_data?
    user.days.where("water_ml > 0").exists?
  end

  def weight_data?
    user.weight_entries.exists?
  end

  def body_measurement_data?
    user.body_measurements.exists?
  end

  def day_note_data?
    user.days.where.not(note: [nil, ""])
        .or(user.days.where.not(mood: nil))
        .or(user.days.where.not(energy_level: nil))
        .or(user.days.where.not(sleep_quality: nil))
        .exists?
  end
end
