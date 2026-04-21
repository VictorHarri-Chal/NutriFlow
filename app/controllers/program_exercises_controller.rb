class ProgramExercisesController < ApplicationController
  before_action :set_program
  before_action :set_day
  before_action :set_exercise, only: [:update, :destroy]

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

  private

  def set_program
    @program = current_user.workout_programs.find(params[:workout_program_id])
  end

  def set_day
    @day = @program.program_days.find(params[:program_day_id])
  end

  def set_exercise
    @exercise = @day.program_exercises.find(params[:id])
  end

  def exercise_params
    params.require(:program_exercise).permit(:exercise_id, :sets, :reps_target, :weight_target,
                                             :rest_seconds, :notes)
  end
end
