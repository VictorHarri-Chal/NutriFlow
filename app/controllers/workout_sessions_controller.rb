class WorkoutSessionsController < ApplicationController
  include CalendarData

  before_action :set_day,             only: [:new, :create]
  before_action :set_workout_session, only: [:edit, :update, :destroy]

  def new
    @active_program  = current_user.workout_programs.find_by(is_active: true)
    @training_days   = @active_program
                         &.program_days
                         &.includes(:program_exercises)
                         &.select { |d| d.program_exercises.any? } || []

    # Show picker when active program has training days and no choice made yet
    if @training_days.any? && params[:program_day_id].blank? && params[:mode].blank?
      @show_picker = true
      return
    end

    @workout_session = @day.workout_sessions.build

    # Pre-fill from a program day if requested
    if params[:program_day_id].present? && @active_program
      program_day = @active_program.program_days
                                   .includes(program_exercises: :exercise)
                                   .find_by(id: params[:program_day_id])
      if program_day
        # Pre-fill session metadata
        @workout_session.duration_minutes = program_day.duration_minutes if program_day.duration_minutes.present?
        @workout_session.notes = program_day.notes if program_day.notes.present?

        program_day.program_exercises.each do |pe|
          next unless pe.exercise.present?
          pe.sets.times do |i|
            set = @workout_session.workout_sets.build(
              exercise_id:  pe.exercise_id,
              weight_kg:    pe.weight_target,
              reps:         pe.reps_target.presence || 1,
              position:     @workout_session.workout_sets.size,
              rest_seconds: i == 0 ? pe.rest_seconds : nil,
              notes:        i == 0 ? pe.notes.presence : nil
            )
            set.exercise = pe.exercise
          end
        end
      end
    end
  end

  def create
    @active_program  = current_user.workout_programs.find_by(is_active: true)
    @workout_session = @day.workout_sessions.build(workout_session_params)

    if @workout_session.save
      mark_pr_sets(@workout_session)
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
          render turbo_stream: turbo_stream.update(
            "item_form",
            partial: "workout_sessions/form",
            locals: { day: @day, workout_session: @workout_session }
          ), status: :unprocessable_entity
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @workout_session.update(workout_session_params)
      mark_pr_sets(@workout_session)
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
          render turbo_stream: turbo_stream.update(
            "item_form",
            partial: "workout_sessions/form",
            locals: { day: @day, workout_session: @workout_session }
          ), status: :unprocessable_entity
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

  # Flags each set as a PR if its weight beats the all-time max for that exercise
  # (excluding the current session so it's compared against prior history only).
  def mark_pr_sets(session)
    sets = session.workout_sets.where.not(weight_kg: nil).to_a
    return if sets.empty?

    exercise_ids = sets.map(&:exercise_id).uniq
    previous_maxes = WorkoutSet
      .joins(workout_session: :day)
      .where(exercise_id: exercise_ids, days: { user_id: current_user.id })
      .where.not(workout_session_id: session.id)
      .group(:exercise_id)
      .maximum(:weight_kg)

    sets.each do |ws|
      prev_max = previous_maxes[ws.exercise_id]&.to_f || 0
      is_pr    = ws.weight_kg.to_f > 0 && ws.weight_kg.to_f > prev_max
      ws.update_column(:is_pr, is_pr)
    end
  end

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
      workout_sets_attributes: [:id, :exercise_id, :weight_kg, :reps, :position, :rest_seconds, :notes, :_destroy]
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
