class WeightEntriesController < ApplicationController
  VALID_PERIODS = [30, 90].freeze

  def index
    @entries     = current_user.weight_entries.ordered
    @profile     = current_user.profile
    @today_entry = current_user.weight_entries.find_or_initialize_by(date: Date.today)
    @period      = VALID_PERIODS.include?(params[:period]&.to_i) ? params[:period].to_i : 90

    build_chart_data
    build_stats
  end

  def create
    @weight_entry = current_user.weight_entries.find_or_initialize_by(
      date: weight_entry_params[:date].presence || Date.today
    )
    @weight_entry.weight_kg = weight_entry_params[:weight_kg]

    if @weight_entry.save
      redirect_to weight_entries_path, notice: t("controllers.weight_entries.saved")
    else
      @entries     = current_user.weight_entries.ordered
      @profile     = current_user.profile
      @today_entry = @weight_entry
      @period      = 90
      build_chart_data
      build_stats
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    entry = current_user.weight_entries.find(params[:id])
    entry.destroy
    redirect_to weight_entries_path, notice: t("controllers.weight_entries.deleted")
  end

  private

  def weight_entry_params
    params.require(:weight_entry).permit(:weight_kg, :date)
  end

  def build_chart_data
    since          = @period.days.ago.to_date
    period_entries = @entries.where("date >= ?", since)

    @chart_labels = period_entries.map { |e| l(e.date, format: :short) }
    @chart_data   = period_entries.map { |e| e.weight_kg.to_f }
    @chart_goal   = @profile&.goal_weight&.to_f || 0

    trend_src = @entries.last(14)
    return unless trend_src.size >= 5

    slope, intercept = linear_regression(trend_src)
    n                = trend_src.size
    last_date        = trend_src.last.date
    @trend_weekly    = (slope * 7).round(1)

    return unless @period >= 30

    @proj_labels = (1..14).map { |i| l(last_date + i.days, format: :short) }
    @proj_data   = (1..14).map { |i| (intercept + slope * (n - 1 + i)).round(2) }
  end

  def build_stats
    @current_weight = @entries.last&.weight_kg
    return unless @current_weight

    ref_30d = @entries.where("date <= ?", 30.days.ago.to_date).last
    ref_90d = @entries.where("date <= ?", 90.days.ago.to_date).last

    @delta_30d = ref_30d ? (@current_weight - ref_30d.weight_kg).round(1) : nil
    @delta_90d = ref_90d ? (@current_weight - ref_90d.weight_kg).round(1) : nil

    if @profile&.height.present?
      height_m     = @profile.height / 100.0
      @bmi         = (@current_weight / height_m**2).round(1)
      @bmi_category = case @bmi
                      when ...18.5 then :underweight
                      when 18.5...25 then :normal
                      when 25...30 then :overweight
                      else :obese
                      end
    end

    @goal_delta       = @profile&.goal_weight ? (@current_weight - @profile.goal_weight).round(1) : nil
    @positive_is_good = @profile&.goal_weight.present? && @profile.goal_weight > @current_weight
  end

  def linear_regression(entries)
    n     = entries.size
    xs    = (0...n).map(&:to_f)
    ys    = entries.map { |e| e.weight_kg.to_f }

    sum_x  = xs.sum
    sum_y  = ys.sum
    sum_xy = xs.zip(ys).sum { |x, y| x * y }
    sum_x2 = xs.sum { |x| x**2 }

    denom     = n * sum_x2 - sum_x**2
    slope     = denom.zero? ? 0.0 : (n * sum_xy - sum_x * sum_y) / denom
    intercept = (sum_y - slope * sum_x) / n

    [slope, intercept]
  end
end
