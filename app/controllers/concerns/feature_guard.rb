module FeatureGuard
  extend ActiveSupport::Concern

  private

  def require_workout_section!
    redirect_to root_path, alert: t("feature_guard.workout_disabled") unless current_user.show_workout_section?
  end

  def require_cardio_section!
    redirect_to root_path, alert: t("feature_guard.cardio_disabled") unless current_user.show_cardio_section?
  end

  def require_weight_tracking!
    redirect_to root_path, alert: t("feature_guard.weight_disabled") unless current_user.show_weight_tracking?
  end

  def require_water_tracking!
    redirect_to root_path, alert: t("feature_guard.water_disabled") unless current_user.show_water_tracking?
  end
end
