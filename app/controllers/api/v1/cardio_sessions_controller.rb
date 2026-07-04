class Api::V1::CardioSessionsController < Api::V1::BaseController
  before_action :set_day
  before_action :set_session, only: [:update, :destroy]

  def create
    @cardio_session = @day.cardio_sessions.build(cardio_session_params)
    inject_weight(@cardio_session)
    if @cardio_session.save
      render json: session_json(@cardio_session), status: :created
    else
      render json: { errors: @cardio_session.errors }, status: :unprocessable_entity
    end
  end

  def update
    inject_weight(@cardio_session)
    if @cardio_session.update(cardio_session_params)
      render json: session_json(@cardio_session)
    else
      render json: { errors: @cardio_session.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @cardio_session.destroy
    render json: {}, status: :no_content
  end

  private

  def set_day
    @day = current_user.days.find_or_create_by!(date: params[:day_date])
  end

  def set_session
    @cardio_session = @day.cardio_sessions.find(params[:id])
  end

  def cardio_session_params
    params.permit(
      :notes,
      cardio_blocks_attributes: [
        :id, :machine, :duration_minutes, :speed_kmh, :incline_percent,
        :resistance_level, :distance_km, :position, :_destroy
      ]
    )
  end

  # Inject user weight into each CardioBlock before_save triggers.
  # Uses .target to read in-memory blocks (new records via nested attributes
  # and loaded records alike) without triggering an extra DB query.
  def inject_weight(session)
    weight = current_user.profile&.weight&.to_f || 75.0
    session.cardio_blocks.target.each { |b| b.user_weight_kg = weight }
  end

  def session_json(s)
    {
      id:              s.id,
      notes:           s.notes,
      total_duration:  s.total_duration,
      total_calories:  s.total_calories,
      blocks:          s.cardio_blocks.order(:position).map { |b|
        {
          id:               b.id,
          machine:          b.machine,
          duration_minutes: b.duration_minutes,
          speed_kmh:        b.speed_kmh,
          incline_percent:  b.incline_percent,
          resistance_level: b.resistance_level,
          distance_km:      b.distance_km,
          calories_burned:  b.calories_burned,
          position:         b.position
        }
      }
    }
  end
end
