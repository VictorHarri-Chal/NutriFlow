class Api::V1::WorkoutSessionsController < Api::V1::BaseController
  before_action :set_day
  before_action :set_session, only: [:update, :destroy]

  def create
    @workout_session = @day.workout_sessions.build(workout_session_params)
    if @workout_session.save
      detect_prs(@workout_session)
      compute_and_save_calories(@workout_session)
      render json: session_json(@workout_session.reload), status: :created
    else
      render json: { errors: @workout_session.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @workout_session.update(workout_session_params)
      detect_prs(@workout_session)
      compute_and_save_calories(@workout_session)
      render json: session_json(@workout_session.reload)
    else
      render json: { errors: @workout_session.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_session.destroy
    render json: {}, status: :no_content
  end

  private

  def set_day
    @day = current_user.days.find_or_create_by!(date: params[:day_date])
  end

  def set_session
    @workout_session = @day.workout_sessions.find(params[:id])
  end

  def workout_session_params
    params.permit(
      :duration_minutes, :rpe, :notes,
      workout_sets_attributes: [
        :id, :exercise_id, :weight_kg, :reps, :position, :rest_seconds, :notes, :_destroy
      ]
    )
  end

  def detect_prs(session)
    session.workout_sets.reload.each do |set|
      next unless set.exercise_id.present? && set.weight_kg.present?

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
  end

  def compute_and_save_calories(session)
    weight = current_user.profile&.weight&.to_f
    kcal   = session.estimated_calories(weight)
    session.update_column(:calories_burned, kcal) if kcal.present? && session.calories_burned != kcal
  end

  def session_json(s)
    {
      id:               s.id,
      duration_minutes: s.duration_minutes,
      rpe:              s.rpe,
      notes:            s.notes,
      calories_burned:  s.calories_burned,
      sets:             s.workout_sets.includes(:exercise).map { |ws|
        {
          id:          ws.id,
          exercise_id: ws.exercise_id,
          exercise_name: ws.exercise&.name,
          weight_kg:   ws.weight_kg,
          reps:        ws.reps,
          position:    ws.position,
          rest_seconds: ws.rest_seconds,
          notes:       ws.notes,
          is_pr:       ws.is_pr
        }
      }
    }
  end
end
