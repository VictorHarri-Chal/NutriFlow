# frozen_string_literal: true

class SettingsController < ApplicationController
  include SettingsDataLoadable

  TABS = {
    "general"         => { icon: "fa-sliders",        label_key: "general" },
    "preferences"     => { icon: "fa-toggle-on",      label_key: "preferences" },
    "day_food_groups" => { icon: "fa-utensils",       label_key: "food_groups" },
    "food_labels"     => { icon: "fa-tag",             label_key: "food_labels" },
    "security"        => { icon: "fa-shield-halved",   label_key: "security" }
  }.freeze

  def show
    load_settings_data(active_tab: params[:tab])
  end

  def update
    if current_user.update(general_params)
      I18n.locale = current_user.locale.to_sym
      redirect_to setting_path(tab: 'general'), notice: t("controllers.settings.locale_updated")
    else
      redirect_to setting_path(tab: 'general'), alert: t("controllers.settings.locale_error")
    end
  end

  def update_preferences
    # User#stop_active_fast_if_tracking_disabled does the actual stopping — this
    # only needs to know beforehand whether that's about to happen, for the flash.
    fast_being_stopped = current_user.show_fasting_tracking? &&
                         preferences_params[:show_fasting_tracking] == "0" &&
                         current_user.fasting_sessions.active.exists?

    if current_user.update(preferences_params)
      notice = fast_being_stopped ? t("controllers.settings.preferences_updated_fasting_stopped") : t("controllers.settings.preferences_updated")
      redirect_to setting_path(tab: 'preferences'), notice: notice
    else
      redirect_to setting_path(tab: 'preferences'), alert: t("controllers.settings.preferences_error")
    end
  end

  def reorder_calendar_sections
    if current_user.update(section_order: Array(params[:ids]))
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def sign_out_other_sessions
    current_user.invalidate_other_sessions!
    bypass_sign_in(current_user)
    redirect_to setting_path(tab: 'security'), notice: t("controllers.settings.other_sessions_signed_out")
  end

  def reset_data
    current_user.reset_all_data!
    redirect_to root_path, notice: t("controllers.settings.data_reset")
  end

  private

  def general_params
    params.permit(:locale, :time_zone)
  end

  def preferences_params
    params.require(:user).permit(
      :show_day_note, :show_workout_section, :show_cardio_section,
      :show_water_tracking, :show_tdee_breakdown, :show_weight_tracking,
      :show_body_measurements, :show_fasting_tracking
    )
  end
end
