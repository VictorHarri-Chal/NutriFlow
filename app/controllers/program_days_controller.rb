class ProgramDaysController < ApplicationController
  before_action :set_program
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

  private

  def set_program
    @program = current_user.workout_programs.find(params[:workout_program_id])
  end

  def set_day
    @day = @program.program_days.find(params[:id])
  end

  def program_day_params
    params.require(:program_day).permit(:name, :duration_minutes, :notes)
  end
end
