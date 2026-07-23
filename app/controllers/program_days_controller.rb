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
    target_day = @program.program_days.find(params[:target_day_id])
    target_day.program_exercises.destroy_all
    @day.copy_exercises_to!(target_day)
    @program.preload_tension_balance_data!
    flash.now[:notice] = t("views.workout_programs.day.copy_success")
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @program, notice: flash.now[:notice] }
    end
  end

  private

  def set_day
    @day = ProgramDay.joins(:workout_program)
                     .includes(program_exercises: [:exercise, :program_exercise_sets])
                     .where(workout_programs: { user_id: current_user.id })
                     .find(params[:id])
    @program = @day.workout_program
  end

  def program_day_params
    params.require(:program_day).permit(:name, :duration_minutes, :notes)
  end
end
