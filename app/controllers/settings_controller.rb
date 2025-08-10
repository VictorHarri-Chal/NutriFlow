# frozen_string_literal: true

class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @minimum_password_length = User.password_length.min
    @day_food_groups = current_user.day_food_groups.includes(:day_foods)
    @day_food_group = DayFoodGroup.new
    @food_labels = current_user.food_labels.includes(:foods)
    @food_label = FoodLabel.new
    @active_tab = params[:tab] || 'general'
  end

  private
end
