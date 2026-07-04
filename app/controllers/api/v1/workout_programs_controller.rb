class Api::V1::WorkoutProgramsController < Api::V1::BaseController
  before_action :set_program, only: [:show, :update, :destroy, :activate, :duplicate]

  def index
    @programs = current_user.workout_programs.order(updated_at: :desc)
    render :index
  end

  def show
    render :show
  end

  def create
    @program = current_user.workout_programs.build(program_params)
    if @program.save
      render :show, status: :created
    else
      render json: { errors: @program.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @program.update(program_params)
      render :show
    else
      render json: { errors: @program.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @program.destroy
    render json: {}, status: :no_content
  end

  def activate
    @program.activate!
    render :show
  end

  def duplicate
    new_program = current_user.workout_programs.create!(
      name:       "#{@program.name} (copie)",
      split_type: @program.split_type,
      is_active:  false
    )

    @program.program_days.includes(program_exercises: :exercise).each do |pd|
      new_pd = new_program.program_days.find_by(day_of_week: pd.day_of_week)
      new_pd ||= new_program.program_days.create!(
        day_of_week:      pd.day_of_week,
        name:             pd.name,
        duration_minutes: pd.duration_minutes,
        notes:            pd.notes
      )
      new_pd.update!(name: pd.name, duration_minutes: pd.duration_minutes, notes: pd.notes)

      pd.program_exercises.order(:position).each do |pe|
        new_pd.program_exercises.create!(
          exercise_id:  pe.exercise_id,
          sets:         pe.sets,
          reps_target:  pe.reps_target,
          weight_target: pe.weight_target,
          rest_seconds: pe.rest_seconds,
          position:     pe.position,
          notes:        pe.notes
        )
      end
    end

    @program = new_program
    render :show, status: :created
  end

  private

  def set_program
    @program = current_user.workout_programs.find(params[:id])
  end

  def program_params
    params.permit(:name, :split_type)
  end
end
