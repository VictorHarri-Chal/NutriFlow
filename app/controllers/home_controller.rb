class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  layout "landing"

  def index
    return redirect_to calendars_path if user_signed_in?

    body_parts = ["back", "chest", "upper legs", "shoulders", "upper arms", "cardio", "waist", "lower legs"]
    @exercises = body_parts.filter_map do |part|
      Exercise.global.with_gif.where(body_part: part).order(:name).first
    end
  end
end
