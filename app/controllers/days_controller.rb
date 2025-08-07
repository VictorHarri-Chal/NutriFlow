class DaysController < ApplicationController
  def show
    @day = Day.find_by(date: params[:id]) || Day.create(date: params[:id])
    @day_foods = @day.day_foods.includes(:food)

    @total_calories = @day.total_calories
    @total_proteins = @day.total_proteins
    @total_carbs = @day.total_carbs
    @total_fats = @day.total_fats
    @total_sugars = @day.total_sugars
  end

  def add_food
    @day = Day.find_or_create_by(date: params[:date])
    @food = Food.find(params[:food_id])
    @day_food = @day.day_foods.build(food: @food, quantity: params[:quantity] || 1.0)

    if @day_food.save
      redirect_to day_path(@day.date), notice: "Aliment ajouté avec succès."
    else
      redirect_to day_path(@day.date), alert: "Erreur lors de l'ajout de l'aliment."
    end
  end
end
