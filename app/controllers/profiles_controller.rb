# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :set_profile, only: [:show, :edit, :update]

  def show
    @user = current_user
    @calories_maintenance = @profile.calculate_calories_needed_maintenance
    @calories_weight_loss = @profile.calculate_calories_needed_weight_loss
    @calories_muscle_gain = @profile.calculate_calories_needed_muscle_gain
    @protein_goal         = @profile.daily_protein_goal
    @fats_goal            = @profile.daily_fats_goal
    @carbs_goal           = @profile.daily_carbs_goal
    if @profile.weight.present? && @profile.height.present?
      @bmi = (@profile.weight.to_f / ((@profile.height.to_f / 100) ** 2)).round(1)
    end
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to profile_path, notice: t("controllers.profiles.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = current_user.profile
    redirect_to root_path unless @profile
  end

  def profile_params
    params.require(:profile).permit(
      :name,
      :weight,
      :height,
      :age,
      :gender,
      :activity_level,
      :goal
    )
  end
end
