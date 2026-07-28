class CalendarsController < ApplicationController
  include CalendarData
  include DateParseable

  def index
    selected_date = parse_date(params[:date])
    day = find_or_create_day(selected_date)
    load_calendar_data(day)
    load_fasting_data if current_user.show_fasting_tracking?
    @selected_date = selected_date
    load_month_heatmap(selected_date, params[:heatmap_month])
  end

  def copy_yesterday
    target_date = parse_date(params[:date])
    yesterday   = target_date - 1.day

    yesterday_day = current_user.days
                                .includes(:day_foods, day_recipes: :day_recipe_items)
                                .find_by(date: yesterday)
    unless yesterday_day
      return redirect_to calendars_path(date: target_date.to_s),
                         alert: t("views.calendars.copy_nothing_to_copy")
    end

    today_day = find_or_create_day(target_date)

    ActiveRecord::Base.transaction do
      yesterday_day.day_foods.each do |df|
        today_day.day_foods.create!(
          food_id:        df.food_id,
          food_name:      df.food_name,
          food_snapshot:  df.food_snapshot,
          quantity:       df.quantity,
          day_food_group: df.day_food_group
        )
      end
      yesterday_day.day_recipes.each do |dr|
        copy = today_day.day_recipes.build(
          recipe_id:      dr.recipe_id,
          recipe_name:    dr.recipe_name,
          day_food_group: dr.day_food_group
        )
        dr.day_recipe_items.each do |item|
          copy.day_recipe_items.build(
            food_id:       item.food_id,
            food_name:     item.food_name,
            food_snapshot: item.food_snapshot,
            quantity:      item.quantity,
            unit:          item.unit
          )
        end
        copy.save!
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
