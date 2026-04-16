class CalendarsController < ApplicationController
  include CalendarData
  include DateParseable

  def index
    selected_date = parse_date(params[:date])
    day = find_or_create_day(selected_date)
    load_calendar_data(day)
    @selected_date = selected_date
  end

  def copy_yesterday
    target_date = parse_date(params[:date])
    yesterday   = target_date - 1.day

    yesterday_day = current_user.days
                                .includes(day_foods: :food,
                                          day_recipes: { recipe: { recipe_items: :food } })
                                .find_by(date: yesterday)
    unless yesterday_day
      return redirect_to calendars_path(date: target_date.to_s),
                         alert: t("views.calendars.copy_nothing_to_copy")
    end

    today_day = find_or_create_day(target_date)

    ActiveRecord::Base.transaction do
      yesterday_day.day_foods.each do |df|
        today_day.day_foods.create!(
          food:             df.food,
          quantity:         df.quantity,
          day_food_group:   df.day_food_group
        )
      end
      yesterday_day.day_recipes.each do |dr|
        today_day.day_recipes.create!(
          recipe:             dr.recipe,
          quantity:           dr.quantity,
          day_food_group:     dr.day_food_group,
          use_recipe_quantity: dr.use_recipe_quantity
        )
      end
    end

    redirect_to calendars_path(date: target_date.to_s),
                notice: t("views.calendars.copy_success")
  rescue ActiveRecord::RecordInvalid
    redirect_to calendars_path(date: target_date.to_s),
                alert: t("views.calendars.copy_error")
  end

  private

  def find_or_create_day(date)
    current_user.days.find_or_create_by(date: date)
  rescue ActiveRecord::RecordNotUnique
    current_user.days.find_by!(date: date)
  end
end
