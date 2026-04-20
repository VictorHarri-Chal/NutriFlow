class WorkoutSessionsController < ApplicationController
  include CalendarData

  before_action :set_day,             only: [:new, :create]
  before_action :set_workout_session, only: [:edit, :update, :destroy]

  def new
    @workout_session = @day.workout_sessions.build
  end

  def create
    @workout_session = @day.workout_sessions.build(workout_session_params)

    if @workout_session.save
      compute_calories(@workout_session)
      load_calendar_data(@day)
      @selected_date = @day.date
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to calendars_path(date: @day.date) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "item_form",
            partial: "workout_sessions/form",
            locals: { day: @day, workout_session: @workout_session }
          )
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @workout_session.update(workout_session_params)
      compute_calories(@workout_session)
      load_calendar_data(@day)
      @selected_date = @day.date
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to calendars_path(date: @day.date) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "item_form",
            partial: "workout_sessions/form",
            locals: { day: @day, workout_session: @workout_session }
          )
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @workout_session.destroy
    load_calendar_data(@day)
    @selected_date = @day.date
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to calendars_path(date: @day.date) }
    end
  end

  private

  def set_day
    @day = current_user.days.find(params[:day_id])
  end

  def set_workout_session
    @workout_session = WorkoutSession.joins(:day)
                                     .where(days: { user_id: current_user.id })
                                     .find(params[:id])
    @day = @workout_session.day
  end

  def workout_session_params
    params.require(:workout_session).permit(
      :duration_minutes, :rpe, :notes,
      workout_sets_attributes: [:id, :exercise_id, :weight_kg, :reps, :position, :_destroy]
    )
  end

  def compute_calories(session)
    session.update_column(:calories_burned, nil)
    session.reload
    session.workout_sets.reload
    profile    = current_user.profile
    raw_weight = profile&.weight.to_f
    weight     = raw_weight > 0 ? raw_weight : 75.0
    calories   = session.estimated_calories(weight)
    session.update_column(:calories_burned, calories)
  end
end
