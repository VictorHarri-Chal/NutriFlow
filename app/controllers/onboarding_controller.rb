class OnboardingController < ApplicationController
  layout "onboarding"

  before_action :set_profile

  def edit
    redirect_to root_path if @profile.onboarding_complete?
  end

  def update
    if @profile.update(onboarding_params)
      redirect_to calendars_path, notice: t("controllers.onboarding.completed")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = current_user.profile
  end

  def onboarding_params
    params.require(:profile).permit(:name, :date_of_birth, :weight, :height, :gender)
  end
end
