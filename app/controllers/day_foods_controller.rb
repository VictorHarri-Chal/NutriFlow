class DayFoodsController < ApplicationController
  before_action :set_day, only: [:new, :create]
  before_action :set_day_food, only: [:edit, :update, :destroy]

  def new
    @day_food = @day.day_foods.build
  end

  def create
    @day_food = @day.day_foods.build(day_food_params)

    if @day_food.save
      redirect_to calendars_path(date: @day.date), notice: "Aliment ajouté avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @day_food.update(day_food_params)
      redirect_to calendars_path(date: @day_food.day.date), notice: "Aliment mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    day_date = @day_food.day.date
    @day_food.destroy
    redirect_to calendars_path(date: day_date), notice: "Aliment supprimé avec succès."
  end

  private

  def set_day
    @day = Day.find(params[:day_id])
  end

  def set_day_food
    @day_food = DayFood.find(params[:id])
  end

  def day_food_params
    params.require(:day_food).permit(:food_id, :quantity)
  end
end
