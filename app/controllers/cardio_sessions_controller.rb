class CardioSessionsController < ApplicationController
  include CalendarData

  before_action :set_day,            only: [:new, :create]
  before_action :set_cardio_session, only: [:edit, :update, :destroy]

  def new
    @cardio_session = @day.cardio_sessions.build
    @cardio_session.cardio_blocks.build
  end

  def create
    @cardio_session = @day.cardio_sessions.build(cardio_session_params)
    inject_weight_into_blocks(@cardio_session)

    if @cardio_session.save
      load_calendar_data(@day)
      @selected_date = @day.date
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to calendars_path(date: @day.date) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "item_form",
            partial: "cardio_sessions/form",
            locals: { day: @day, cardio_session: @cardio_session }
          ), status: :unprocessable_entity
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @cardio_session.cardio_blocks.build if @cardio_session.cardio_blocks.empty?
  end

  def update
    @cardio_session.assign_attributes(cardio_session_params)
    inject_weight_into_blocks(@cardio_session)
    if @cardio_session.save
      load_calendar_data(@day)
      @selected_date = @day.date
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to calendars_path(date: @day.date) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "item_form",
            partial: "cardio_sessions/form",
            locals: { day: @day, cardio_session: @cardio_session }
          ), status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @cardio_session.destroy
    load_calendar_data(@day)
    @selected_date = @day.date
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to calendars_path(date: @day.date) }
    end
  end

  private

  def inject_weight_into_blocks(cardio_session)
    weight = current_user.profile&.weight.to_f
    return unless weight > 0
    cardio_session.cardio_blocks.each { |b| b.user_weight_kg = weight }
  end

  def set_day
    @day = current_user.days.find(params[:day_id])
  end

  def set_cardio_session
    @cardio_session = CardioSession.joins(:day)
                                   .where(days: { user_id: current_user.id })
                                   .find(params[:id])
    @day = @cardio_session.day
  end

  def cardio_session_params
    params.require(:cardio_session).permit(
      :notes,
      cardio_blocks_attributes: [
        :id, :machine, :duration_minutes, :speed_kmh,
        :incline_percent, :resistance_level, :distance_km,
        :position, :_destroy
      ]
    )
  end
end
