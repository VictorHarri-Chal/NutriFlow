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

  def copy_to
    @target_day = @program.program_days.find(params[:target_day_id])
    @target_day.program_exercises.destroy_all
    @day.program_exercises.order(:position).each do |pe|
      @target_day.program_exercises.create!(
        exercise_id:   pe.exercise_id,
        sets:          pe.sets,
        reps_target:   pe.reps_target,
        weight_target: pe.weight_target,
        rest_seconds:  pe.rest_seconds,
        notes:         pe.notes,
        position:      pe.position
      )
    end
    @target_day = @program.program_days.includes(program_exercises: :exercise).find(@target_day.id)
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
    @day = @program.program_days.find(params[:id])
  end

  def program_day_params
    params.require(:program_day).permit(:name, :duration_minutes, :notes)
  end
end
