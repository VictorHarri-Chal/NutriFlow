class DailyCalorieRequirementsController < ApplicationController
  def show
    @profile = current_user.profile
    if (base = @profile.base_tdee)
      @calories_maintenance = base
      @calories_weight_loss = (base * 0.85).round
      @calories_muscle_gain = (base * 1.10).round
    end
    @protein_goal = @profile.daily_protein_goal
    @fats_goal    = @profile.daily_fats_goal
    @carbs_goal   = @profile.daily_carbs_goal
  end
end
