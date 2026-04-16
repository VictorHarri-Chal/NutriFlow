class WeightEntriesController < ApplicationController
  def index
    @entries  = current_user.weight_entries.ordered
    @profile  = current_user.profile
    @today_entry = current_user.weight_entries.find_or_initialize_by(date: Date.today)

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
    last_90 = @entries.last(90)
    @chart_labels = last_90.map { |e| l(e.date, format: :short) }
    @chart_data   = last_90.map { |e| e.weight_kg.to_f }
    @chart_goal   = @profile&.goal_weight&.to_f || 0
  end

  def build_stats
    @current_weight = @entries.last&.weight_kg
    return unless @current_weight

    ref_30d = @entries.where("date <= ?", 30.days.ago.to_date).last
    ref_90d = @entries.where("date <= ?", 90.days.ago.to_date).last

    @delta_30d = ref_30d ? (@current_weight - ref_30d.weight_kg).round(1) : nil
    @delta_90d = ref_90d ? (@current_weight - ref_90d.weight_kg).round(1) : nil

    if @profile&.height.present?
      height_m = @profile.height / 100.0
      @bmi     = (@current_weight / height_m**2).round(1)
    end

    @goal_delta = @profile&.goal_weight ? (@current_weight - @profile.goal_weight).round(1) : nil
  end
end
