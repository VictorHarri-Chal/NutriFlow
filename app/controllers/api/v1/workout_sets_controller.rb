class Api::V1::WorkoutSetsController < Api::V1::BaseController
  before_action :set_day
  before_action :set_workout_session
  before_action :set_workout_set, only: [:update, :destroy]

  def create
    @workout_set = @workout_session.workout_sets.build(workout_set_params)
    if @workout_set.save
      detect_pr(@workout_set)
      render json: workout_set_json(@workout_set), status: :created
    else
      render json: { errors: @workout_set.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @workout_set.update(workout_set_params)
      detect_pr(@workout_set)
      render json: workout_set_json(@workout_set)
    else
      render json: { errors: @workout_set.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_set.destroy
    render json: {}, status: :no_content
  end

  private

  def set_day
    @day = current_user.days.find_or_create_by!(date: params[:day_date])
  end

  def set_workout_session
    @workout_session = @day.workout_sessions.find(params[:workout_session_id])
  end

  def set_workout_set
    @workout_set = @workout_session.workout_sets.find(params[:id])
  end

  def workout_set_params
    params.permit(:exercise_id, :weight_kg, :reps, :position, :rest_seconds, :notes)
  end

  def detect_pr(set)
    return unless set.exercise_id.present? && set.weight_kg.present?

    all_time_max = WorkoutSet
      .joins(workout_session: { day: {} })
      .where(
        days: { user_id: current_user.id },
        exercise_id: set.exercise_id
      )
      .where.not(id: set.id)
      .maximum(:weight_kg)

    is_pr = all_time_max.nil? || set.weight_kg > all_time_max
    set.update_column(:is_pr, is_pr)
  end

  def workout_set_json(ws)
    {
      id:            ws.id,
      exercise_id:   ws.exercise_id,
      exercise_name: ws.exercise&.name,
      weight_kg:     ws.weight_kg,
      reps:          ws.reps,
      position:      ws.position,
      rest_seconds:  ws.rest_seconds,
      is_pr:         ws.is_pr
    }
  end
end
