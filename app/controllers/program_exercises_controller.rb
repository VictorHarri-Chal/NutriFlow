class ProgramExercisesController < ApplicationController
  include FeatureGuard

  before_action :require_workout_section!
  before_action :set_program_day, only: [:new, :create, :reorder]
  before_action :set_exercise,    only: [:edit, :update, :destroy, :move]

  def new
    exercise = Exercise.accessible_to(current_user).find(params[:exercise_id])
    @exercise = @day.program_exercises.build(exercise: exercise)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @program }
    end
  end

  def create
    @exercise = @day.program_exercises.build(exercise_params)
    if @exercise.save
      @exercise = ProgramExercise.includes(:exercise, :program_exercise_sets).find(@exercise.id)
      @program.preload_tension_balance_data!
      @day.recompute_estimated_duration!
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @program }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          # Without a resolved exercise there's nothing valid to render the modal for
          # (e.g. a tampered/missing exercise_id) — fail without re-rendering it.
          @exercise.exercise ? render(:new, status: :unprocessable_entity) : head(:unprocessable_entity)
        end
        format.html { redirect_to @program }
      end
    end
  end

  def edit
    @last_performance = last_performance_for(@exercise.exercise_id)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @program }
    end
  end

  def update
    if @exercise.update(exercise_params)
      @day.recompute_estimated_duration!
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @program }
      end
    else
      @last_performance = last_performance_for(@exercise.exercise_id)
      respond_to do |format|
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { redirect_to @program }
      end
    end
  end

  def destroy
    @exercise.destroy
    @program.preload_tension_balance_data!
    @day.recompute_estimated_duration!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @program }
    end
  end

  def move
    target_day = @program.program_days.find(params[:target_day_id])
    new_position = params[:position].to_i

    @source_day = @day
    @target_day = target_day

    # Structural move only — skip validations (a legacy zero-set exercise must
    # still be movable), consistent with the position repack below.
    @exercise.update_columns(program_day_id: target_day.id, position: new_position)

    # Repack positions on both days to avoid gaps
    @source_day.program_exercises.order(:position).each_with_index do |pe, i|
      pe.update_column(:position, i)
    end
    @target_day.program_exercises.order(:position).each_with_index do |pe, i|
      pe.update_column(:position, i)
    end

    # Reload with :exercise preloaded for the turbo_stream render below
    @source_day = ProgramDay.includes(program_exercises: [:exercise, :program_exercise_sets]).find(@source_day.id)
    @target_day = ProgramDay.includes(program_exercises: [:exercise, :program_exercise_sets]).find(@target_day.id)

    @source_day.recompute_estimated_duration!
    @target_day.recompute_estimated_duration!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @program }
    end
  end

  def reorder
    ids = Array(params[:ids]).map(&:to_i)
    return head :bad_request if ids.empty?
    ids.each_with_index do |id, index|
      @day.program_exercises.where(id: id).update_all(position: index)
    end
    head :ok
  end

  private

  def set_program_day
    @day = ProgramDay.joins(:workout_program)
                     .where(workout_programs: { user_id: current_user.id })
                     .find(params[:program_day_id])
    @program = @day.workout_program
  end

  def set_exercise
    @exercise = ProgramExercise.includes(:exercise, :program_exercise_sets)
                               .joins(program_day: :workout_program)
                               .where(workout_programs: { user_id: current_user.id })
                               .find(params[:id])
    @day     = @exercise.program_day
    @program = @day.workout_program
  end

  def exercise_params
    params.require(:program_exercise).permit(
      :exercise_id, :rest_seconds, :notes,
      program_exercise_sets_attributes: [:id, :position, :reps_target, :weight_target, :rpe, :_destroy, set_types: []]
    )
  end

  def last_performance_for(exercise_id)
    last_set = WorkoutSet.joins(workout_session: :day)
                         .where(exercise_id: exercise_id, days: { user_id: current_user.id })
                         .order(created_at: :desc)
                         .first
    return nil unless last_set

    sets = WorkoutSet.where(workout_session_id: last_set.workout_session_id, exercise_id: exercise_id)
                     .order(:position)
    { at: last_set.created_at, sets: sets }
  end
end
