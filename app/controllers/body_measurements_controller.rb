class BodyMeasurementsController < ApplicationController
  include FeatureGuard
  include MeasurementsTabLoadable

  before_action :require_body_measurements!

  def create
    @body_measurement, saved = upsert_body_measurement

    if saved
      redirect_to weight_entries_path(tab: "mesures"), notice: t("controllers.body_measurements.saved")
    else
      @today_measurement = @body_measurement
      @tab               = "mesures"
      @available_tabs    = compute_available_tabs
      load_measurements_tab
      render "weight_entries/index", status: :unprocessable_entity
    end
  end

  def destroy
    measurement = current_user.body_measurements.find(params[:id])
    measurement.destroy
    redirect_to weight_entries_path(tab: "mesures"), notice: t("controllers.body_measurements.deleted")
  end

  private

  # Upserts by date. Guards against the race where two concurrent requests
  # both miss the initial SELECT and attempt an INSERT for the same
  # user+date — the DB's unique index rejects the second one with
  # RecordNotUnique, which we retry once as an update against the row the
  # other request just created (mirrors CalendarsController#find_or_create_day).
  def upsert_body_measurement
    date = body_measurement_params[:date].presence || Date.today

    measurement = current_user.body_measurements.find_or_initialize_by(date: date)
    measurement.assign_attributes(body_measurement_params.except(:date))
    [measurement, measurement.save]
  rescue ActiveRecord::RecordNotUnique
    measurement = current_user.body_measurements.find_by!(date: date)
    measurement.assign_attributes(body_measurement_params.except(:date))
    [measurement, measurement.save]
  end

  def body_measurement_params
    params.require(:body_measurement).permit(:date, :image, *BodyMeasurement::MEASUREMENT_FIELDS)
  end
end
