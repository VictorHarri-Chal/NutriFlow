class Api::V1::ProfilesController < Api::V1::BaseController
  def show
    render :show
  end

  def update
    if current_user.profile.update(profile_params)
      render :show
    else
      render json: { errors: current_user.profile.errors }, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.permit(
      :name, :weight, :height, :age, :gender, :job_activity_level,
      :default_daily_steps, :goal, :goal_weight, :water_goal_ml
    )
  end
end
