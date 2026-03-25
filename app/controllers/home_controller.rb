class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  layout "landing"

  def index
    redirect_to calendars_path if user_signed_in?
  end
end
