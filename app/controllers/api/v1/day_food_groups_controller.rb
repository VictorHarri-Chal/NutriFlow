class Api::V1::DayFoodGroupsController < Api::V1::BaseController
  before_action :set_day_food_group, only: [:show, :update, :destroy]

  def index
    @day_food_groups = current_user.day_food_groups.order(:name)
    render :index
  end

  def show
    render :show
  end

  def create
    @day_food_group = current_user.day_food_groups.build(day_food_group_params)
    if @day_food_group.save
      render :show, status: :created
    else
      render json: { errors: @day_food_group.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @day_food_group.update(day_food_group_params)
      render :show
    else
      render json: { errors: @day_food_group.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @day_food_group.destroy
    render json: {}, status: :no_content
  end

  private

  def set_day_food_group
    @day_food_group = current_user.day_food_groups.find(params[:id])
  end

  def day_food_group_params
    params.permit(:name)
  end
end
