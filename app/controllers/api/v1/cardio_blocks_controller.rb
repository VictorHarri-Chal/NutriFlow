class Api::V1::CardioBlocksController < Api::V1::BaseController
  before_action :set_day
  before_action :set_cardio_session
  before_action :set_cardio_block, only: [:update, :destroy]

  def create
    @cardio_block = @cardio_session.cardio_blocks.build(cardio_block_params)
    @cardio_block.user_weight_kg = current_user.profile&.weight&.to_f || 75.0
    if @cardio_block.save
      render json: cardio_block_json(@cardio_block), status: :created
    else
      render json: { errors: @cardio_block.errors }, status: :unprocessable_entity
    end
  end

  def update
    @cardio_block.user_weight_kg = current_user.profile&.weight&.to_f || 75.0
    if @cardio_block.update(cardio_block_params)
      render json: cardio_block_json(@cardio_block)
    else
      render json: { errors: @cardio_block.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @cardio_block.destroy
    render json: {}, status: :no_content
  end

  private

  def set_day
    @day = current_user.days.find_or_create_by!(date: params[:day_date])
  end

  def set_cardio_session
    @cardio_session = @day.cardio_sessions.find(params[:cardio_session_id])
  end

  def set_cardio_block
    @cardio_block = @cardio_session.cardio_blocks.find(params[:id])
  end

  def cardio_block_params
    params.permit(:machine, :duration_minutes, :speed_kmh, :incline_percent, :resistance_level, :distance_km, :position)
  end

  def cardio_block_json(b)
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
  end
end
