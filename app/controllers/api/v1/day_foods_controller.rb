class Api::V1::DayFoodsController < Api::V1::BaseController
  before_action :set_day
  before_action :set_day_food, only: [:update, :destroy]

  def create
    @day_food = @day.day_foods.build(day_food_params)
    validate_day_food_group!
    if @day_food.save
      render json: day_food_json(@day_food), status: :created
    else
      render json: { errors: @day_food.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @day_food.update(day_food_params)
      render json: day_food_json(@day_food)
    else
      render json: { errors: @day_food.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @day_food.destroy
    render json: {}, status: :no_content
  end

  private

  def set_day
    @day = current_user.days.find_or_create_by!(date: params[:day_date])
  end

  def set_day_food
    @day_food = @day.day_foods.find(params[:id])
  end

  def validate_day_food_group!
    return unless params[:day_food_group_id].present?
    group = current_user.day_food_groups.find_by(id: params[:day_food_group_id])
    @day_food.day_food_group = nil unless group
  end

  def day_food_params
    params.permit(:food_id, :quantity, :day_food_group_id)
  end

  def day_food_json(df)
    {
      id:               df.id,
      food_id:          df.food_id,
      food_name:        df.food.name,
      quantity:         df.quantity,
      day_food_group_id: df.day_food_group_id,
      total_calories:   df.total_calories,
      total_proteins:   df.total_proteins,
      total_carbs:      df.total_carbs,
      total_fats:       df.total_fats,
      total_sugars:     df.total_sugars
    }
  end
end
