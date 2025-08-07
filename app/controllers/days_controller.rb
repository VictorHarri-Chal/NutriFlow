class DaysController < ApplicationController
  def show
    @day = current_user.days.find_by(date: params[:id]) || current_user.days.create(date: params[:id], user: current_user)
    @day_foods = @day.day_foods.includes(:food)

    @total_calories = @day.total_calories
    @total_proteins = @day.total_proteins
    @total_carbs = @day.total_carbs
    @total_fats = @day.total_fats
    @total_sugars = @day.total_sugars
  end

  def add_food
    @day = current_user.days.find_or_create_by(date: params[:date]) do |day|
      day.user = current_user
    end
    @food = current_user.foods.find(params[:food_id])
    @day_food = @day.day_foods.build(food: @food, quantity: params[:quantity] || 1.0)

    if @day_food.save
      redirect_to day_path(@day.date), notice: "Aliment ajouté avec succès."
    else
      redirect_to day_path(@day.date), alert: "Erreur lors de l'ajout de l'aliment."
    end
  end
end
