class Api::V1::SettingsController < Api::V1::BaseController
  def show
    render :show
  end

  def update
    if current_user.update(settings_params)
      render :show
    else
      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.permit(
      :locale,
      :show_day_note,
      :show_workout_section,
      :show_cardio_section,
      :show_water_tracking,
      :show_tdee_breakdown,
      :show_weight_tracking
    )
  end
end
