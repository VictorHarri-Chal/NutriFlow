module FeatureGuard
  extend ActiveSupport::Concern

  private

  def require_workout_section!
    redirect_to root_path, alert: t("feature_guard.workout_disabled") unless current_user.show_workout_section?
  end

  def require_cardio_section!
    redirect_to root_path, alert: t("feature_guard.cardio_disabled") unless current_user.show_cardio_section?
  end

  def require_body_measurements!
    redirect_to root_path, alert: t("feature_guard.measurements_disabled") unless current_user.show_body_measurements?
  end

  def require_water_tracking!
    redirect_to root_path, alert: t("feature_guard.water_disabled") unless current_user.show_water_tracking?
  end

  def require_fasting_tracking!
    redirect_to root_path, alert: t("feature_guard.fasting_disabled") unless current_user.show_fasting_tracking?
  end
end
