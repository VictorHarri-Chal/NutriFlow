class DaysController < ApplicationController
  include DateParseable
  before_action :set_day, only: [:update, :update_water]

  def update
    if @day.update(day_params)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def update_water
    new_value = if params[:amount]
                  [params[:amount].to_i, 0].max
                else
                  [@day.water_ml + params[:delta].to_i, 0].max
                end

    @day.update!(water_ml: new_value)
    @profile = current_user.profile

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to calendars_path(date: @day.date) }
    end
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  private

  def set_day
    @day = current_user.days.find(params[:id])
  end

  def day_params
    params.require(:day).permit(:note, :energy_level, :mood, :sleep_quality)
  end

  public

  def add_food
    date = parse_date(params[:date])
    @day = current_user.days.find_or_create_by(date: date) do |day|
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
