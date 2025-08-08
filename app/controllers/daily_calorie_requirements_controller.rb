class DailyCalorieRequirementsController < ApplicationController
  def show
    @user = current_user
    @profile = @user.profile
    @daily_calorie_requirement = @profile.calculate_calories_needed_maintenance
    @daily_calorie_requirement_weight_loss = @profile.calculate_calories_needed_weight_loss
    @daily_calorie_requirement_muscle_gain = @profile.calculate_calories_needed_muscle_gain
  end
end
