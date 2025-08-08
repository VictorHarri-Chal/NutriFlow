# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :set_profile, only: [:show, :edit, :update]

  def show
    @user = current_user
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to profile_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = current_user.profile
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
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
