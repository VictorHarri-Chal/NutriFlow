class Api::V1::ProgramDaysController < Api::V1::BaseController
  before_action :set_program
  before_action :set_program_day, only: [:update, :destroy, :copy_to]

  def create
    @program_day = @program.program_days.build(program_day_params)
    if @program_day.save
      render json: program_day_json(@program_day), status: :created
    else
      render json: { errors: @program_day.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @program_day.update(program_day_params)
      render json: program_day_json(@program_day)
    else
      render json: { errors: @program_day.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @program_day.destroy
    render json: {}, status: :no_content
  end

  def copy_to
    target = @program.program_days.find(params[:target_day_id])
    target.program_exercises.destroy_all

    @program_day.program_exercises.order(:position).each do |pe|
      target.program_exercises.create!(
        exercise_id:  pe.exercise_id,
        sets:         pe.sets,
        reps_target:  pe.reps_target,
        weight_target: pe.weight_target,
        rest_seconds: pe.rest_seconds,
        position:     pe.position,
        notes:        pe.notes
      )
    end

    render json: program_day_json(target.reload)
  end

  private

  def set_program
    @program = current_user.workout_programs.find(params[:workout_program_id])
  end

  def set_program_day
    @program_day = @program.program_days.find(params[:id])
  end

  def program_day_params
    params.permit(:name, :duration_minutes, :notes, :day_of_week)
  end

  def program_day_json(pd)
    {
      id:               pd.id,
      day_of_week:      pd.day_of_week,
      name:             pd.name,
      duration_minutes: pd.duration_minutes,
      notes:            pd.notes,
      program_exercises: pd.program_exercises.includes(:exercise).order(:position).map { |pe|
        {
          id:            pe.id,
          exercise_id:   pe.exercise_id,
          exercise_name: pe.exercise&.name,
          sets:          pe.sets,
          reps_target:   pe.reps_target,
          weight_target: pe.weight_target,
          rest_seconds:  pe.rest_seconds,
          position:      pe.position,
          notes:         pe.notes
        }
      }
    }
  end
end
