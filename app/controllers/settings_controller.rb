# frozen_string_literal: true

class SettingsController < ApplicationController
  def show
    @user = current_user
    @minimum_password_length = User.password_length.min
    @day_food_groups = current_user.day_food_groups.includes(:day_foods)
    @day_food_group = DayFoodGroup.new
    @food_labels = current_user.food_labels.includes(:foods)
    @food_label = FoodLabel.new
    @active_tab = params[:tab] || 'general'
  end

  def update
    if current_user.update(locale: params[:locale])
      I18n.locale = current_user.locale.to_sym
      redirect_to setting_path(tab: 'general'), notice: t("controllers.settings.locale_updated")
    else
      redirect_to setting_path(tab: 'general'), alert: t("controllers.settings.locale_error")
    end
  end

  private
end
