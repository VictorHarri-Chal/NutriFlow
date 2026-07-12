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
      show_day_note:        day_note_data?
    }
  end

  private

  attr_reader :user

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

  def day_note_data?
    user.days.where.not(note: [nil, ""])
        .or(user.days.where.not(mood: nil))
        .or(user.days.where.not(energy_level: nil))
        .or(user.days.where.not(sleep_quality: nil))
        .exists?
  end
end
