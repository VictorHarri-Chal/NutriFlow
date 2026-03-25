class CalendarsController < ApplicationController
  include CalendarData

  def index
    selected_date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    day = current_user.days.find_or_create_by(date: selected_date) { |d| d.user = current_user }
    load_calendar_data(day)
    @selected_date = selected_date
  end
end
