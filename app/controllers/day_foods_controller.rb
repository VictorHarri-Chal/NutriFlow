class DayFoodsController < ApplicationController
  before_action :set_day, only: [:new, :create]
  before_action :set_day_food, only: [:edit, :update, :destroy]

  def new
    @day_food = @day.day_foods.build
    @day_food_groups = current_user.day_food_groups.order(:name)
  end

  def create
    @day_food = @day.day_foods.build(day_food_params)

    if @day_food.save
      redirect_to calendars_path(date: @day.date)
    else
      @day_food_groups = current_user.day_food_groups.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @day_food_groups = current_user.day_food_groups.order(:name)
  end

  def update
    if @day_food.update(day_food_params)
      redirect_to calendars_path(date: @day_food.day.date)
    else
      @day_food_groups = current_user.day_food_groups.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    day_date = @day_food.day.date
    @day_food.destroy
    redirect_to calendars_path(date: day_date)
  end

  private

  def set_day
    @day = current_user.days.find(params[:day_id])
  end

  def set_day_food
    @day_food = DayFood.joins(:day).where(days: { user_id: current_user.id }).find(params[:id])
  end

  def day_food_params
    params.require(:day_food).permit(:food_id, :quantity, :day_food_group_id)
  end
end
