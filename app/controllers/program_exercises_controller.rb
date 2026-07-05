class ProgramExercisesController < ApplicationController
  before_action :set_program_day, only: [:create, :reorder]
  before_action :set_exercise,    only: [:update, :destroy, :move]

  def create
    @exercise = @day.program_exercises.build(exercise_params)
    if @exercise.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @program }
      end
    else
      head :unprocessable_entity
    end
  end

  def update
    if @exercise.update(exercise_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @program }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @exercise.destroy
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

    @exercise.update!(program_day: target_day, position: new_position)

    # Repack positions on both days to avoid gaps
    @source_day.program_exercises.order(:position).each_with_index do |pe, i|
      pe.update_column(:position, i)
    end
    @target_day.program_exercises.order(:position).each_with_index do |pe, i|
      pe.update_column(:position, i)
    end

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
    @exercise = ProgramExercise.joins(program_day: :workout_program)
                               .where(workout_programs: { user_id: current_user.id })
                               .find(params[:id])
    @day     = @exercise.program_day
    @program = @day.workout_program
  end

  def exercise_params
    params.require(:program_exercise).permit(:exercise_id, :sets, :reps_target, :weight_target,
                                             :rest_seconds, :notes)
  end
end
