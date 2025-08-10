class CalendarsController < ApplicationController
  def index
    @selected_date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @day = current_user.days.find_or_create_by(date: @selected_date) do |day|
      day.user = current_user
    end

    @day_foods = @day.day_foods.includes(:food, :day_food_group)

    @day_foods_by_group = @day_foods.group_by(&:day_food_group)

    @day_foods_without_group = @day_foods_by_group.delete(nil) || []

    @total_calories = @day.total_calories
    @total_proteins = @day.total_proteins
    @total_carbs = @day.total_carbs
    @total_fats = @day.total_fats
    @total_sugars = @day.total_sugars
  end
end
