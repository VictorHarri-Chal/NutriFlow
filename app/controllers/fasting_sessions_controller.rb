class FastingSessionsController < ApplicationController
  include CalendarData
  include FeatureGuard

  before_action :require_fasting_tracking!
  before_action :set_fasting_session, only: [:finish, :destroy]

  def index
    @stats = FastingStatsCalculator.new(current_user).call
    @sessions_pagy, @sessions = pagy(current_user.fasting_sessions.ordered, items: 10)
  end

  def create
    if current_user.fasting_disclaimer_acknowledged_at.nil? && params[:acknowledge_disclaimer].blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "fasting_disclaimer_modal_root",
            partial: "fasting_sessions/disclaimer_modal",
            locals: { protocol: params[:protocol] }
          )
        end
        format.html { redirect_to calendars_path, alert: t("controllers.fasting_sessions.disclaimer_required") }
      end
      return
    end

    current_user.update_column(:fasting_disclaimer_acknowledged_at, Time.current) if current_user.fasting_disclaimer_acknowledged_at.nil?

    @fasting_session = current_user.fasting_sessions.build(protocol: params[:protocol], started_at: Time.current)

    if @fasting_session.save
      load_fasting_data
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to calendars_path }
      end
    else
      redirect_to calendars_path, alert: @fasting_session.errors.full_messages.uniq.join(", ")
    end
  rescue ActiveRecord::RecordNotUnique
    redirect_to calendars_path, alert: t("activerecord.errors.models.fasting_session.attributes.base.active_session_already_exists")
  end

  def finish
    @fasting_session.update!(ended_at: Time.current)
    load_fasting_data
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to calendars_path }
    end
  end

  def destroy
    @fasting_session.destroy
    load_fasting_data
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to calendars_path }
    end
  end

  private

  def set_fasting_session
    @fasting_session = current_user.fasting_sessions.find(params[:id])
  end
end
