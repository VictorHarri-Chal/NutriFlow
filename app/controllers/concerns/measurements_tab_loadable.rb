module MeasurementsTabLoadable
  extend ActiveSupport::Concern

  VALID_PERIODS = [30, 90].freeze

  private

  def compute_available_tabs
    tabs = []
    tabs << "poids"   if current_user.show_weight_tracking?
    tabs << "mesures" if current_user.show_body_measurements?
    tabs
  end

  def load_measurements_tab
    @measurements      = current_user.body_measurements.ordered.with_attached_image
    @today_measurement ||= current_user.body_measurements.find_or_initialize_by(date: Date.today)
    @measurement_type  = BodyMeasurement::MEASUREMENT_FIELDS.map(&:to_s).include?(params[:measurement]) ? params[:measurement] : "waist_cm"
    @period            = VALID_PERIODS.include?(params[:period]&.to_i) ? params[:period].to_i : 30

    @measurements_pagy, @history_measurements = pagy(@measurements.reverse_order, items: 9)

    build_measurement_chart_data
    build_measurement_stats
  end

  def build_measurement_chart_data
    since                = @period.days.ago.to_date
    period_measurements  = @measurements.where("date >= ?", since).select { |m| m.public_send(@measurement_type).present? }

    @measurement_chart_labels = period_measurements.map { |m| l(m.date, format: :short) }
    @measurement_chart_data   = period_measurements.map { |m| m.public_send(@measurement_type).to_f }
  end

  def build_measurement_stats
    latest = @measurements.last
    return unless latest

    @latest_waist        = latest.waist_cm
    @latest_waist_hip    = latest.waist_hip_ratio
    @latest_waist_height = latest.waist_height_ratio
    @latest_body_fat     = latest.estimated_body_fat_percentage
  end
end
