class DaysController < ApplicationController
  before_action :set_day, only: [:update]

  def update
    if @day.update(day_params)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def set_day
    @day = current_user.days.find(params[:id])
  end

  def day_params
    params.require(:day).permit(:note)
  end

  public

  def add_food
    @day = current_user.days.find_or_create_by(date: params[:date]) do |day|
      day.user = current_user
    end
    @food = current_user.foods.find(params[:food_id])
    @day_food = @day.day_foods.build(food: @food, quantity: params[:quantity] || 1.0)

    if @day_food.save
      redirect_to calendars_path(date: @day.date), notice: t("controllers.days.food_added")
    else
      redirect_to calendars_path(date: @day.date), alert: t("controllers.days.food_add_error")
    end
  end
end
