module CalendarData
  extend ActiveSupport::Concern

  private

  def load_month_heatmap(date, heatmap_month = nil)
    month_anchor   = parse_heatmap_month(heatmap_month) || date
    start_of_month = month_anchor.beginning_of_month
    end_of_month   = month_anchor.end_of_month

    month_days = current_user.days
                   .where(date: start_of_month..end_of_month)
                   .includes(day_foods: :food, day_recipes: { recipe: { recipe_items: :food } })

    @month_heatmap = month_days.each_with_object({}) do |d, h|
      foods_cals   = d.day_foods.sum(&:total_calories)
      recipes_cals = d.day_recipes.sum(&:total_calories)
      h[d.date] = (foods_cals + recipes_cals).round
    end

    @heatmap_start = start_of_month
    @heatmap_end   = end_of_month
  end

  def load_calendar_data(day)
    ::CalendarDataLoader.new(current_user, day).call.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def parse_heatmap_month(value)
    return nil if value.blank?

    Date.strptime(value, "%Y-%m")
  rescue ArgumentError, Date::Error
    nil
  end
end
