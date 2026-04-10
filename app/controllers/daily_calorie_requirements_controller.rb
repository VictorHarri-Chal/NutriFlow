class DailyCalorieRequirementsController < ApplicationController
  def show
    @profile = current_user.profile
    @calories_maintenance  = @profile.calculate_calories_needed_maintenance
    @calories_weight_loss  = @profile.calculate_calories_needed_weight_loss
    @calories_muscle_gain  = @profile.calculate_calories_needed_muscle_gain
    @protein_goal          = @profile.daily_protein_goal
    @fats_goal             = @profile.daily_fats_goal
    @carbs_goal            = @profile.daily_carbs_goal
  end
end
