class ProgramDaysController < ApplicationController
  include FeatureGuard

  before_action :require_workout_section!
  before_action :set_day

  def update
    if @day.update(program_day_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @program }
      end
    else
      head :unprocessable_entity
    end
  end

  def copy_to
    @target_day = @program.program_days.find(params[:target_day_id])
    @target_day.program_exercises.destroy_all
    @day.copy_exercises_to!(@target_day)
    @target_day = @program.program_days.includes(program_exercises: :exercise).find(@target_day.id)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @program }
    end
  end

  private

  def set_day
    @day = ProgramDay.joins(:workout_program)
                     .includes(program_exercises: :exercise)
                     .where(workout_programs: { user_id: current_user.id })
                     .find(params[:id])
    @program = @day.workout_program
  end

  def program_day_params
    params.require(:program_day).permit(:name, :duration_minutes, :notes)
  end
end
