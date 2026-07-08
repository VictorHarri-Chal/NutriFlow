# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :set_profile, only: [:show, :edit, :update]

  def show
    @user = current_user
    if (scenarios = @profile.calorie_scenarios)
      @calories_maintenance = scenarios[:maintenance]
      @weight_loss_rate     = scenarios[:weight_loss_rate]
      @muscle_gain_rate     = scenarios[:muscle_gain_rate]
      @calories_weight_loss = scenarios[:weight_loss]
      @calories_muscle_gain = scenarios[:muscle_gain]
    end
    @protein_goal = @profile.daily_protein_goal
    @fats_goal    = @profile.daily_fats_goal
    @carbs_goal   = @profile.daily_carbs_goal
    @bmi = @profile.bmi
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      response.set_header("Turbo-Cache-Control", "no-cache")
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
      :date_of_birth,
      :gender,
      :job_activity_level,
      :default_daily_steps,
      :goal_rate_kg_per_week,
      :goal_weight,
      :water_goal_ml
    )
  end
end
