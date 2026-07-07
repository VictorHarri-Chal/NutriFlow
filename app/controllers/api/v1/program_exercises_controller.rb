class Api::V1::ProgramExercisesController < Api::V1::BaseController
  before_action :set_program
  before_action :set_program_day
  before_action :set_program_exercise, only: [:update, :destroy, :move]

  def create
    @program_exercise = @program_day.program_exercises.build(program_exercise_params)
    if @program_exercise.save
      render json: program_exercise_json(@program_exercise), status: :created
    else
      render json: { errors: @program_exercise.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @program_exercise.update(program_exercise_params)
      render json: program_exercise_json(@program_exercise)
    else
      render json: { errors: @program_exercise.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @program_exercise.destroy
    render json: {}, status: :no_content
  end

  # PATCH /api/v1/workout_programs/:workout_program_id/program_days/:program_day_id/program_exercises/reorder
  # Body: { ids: [3, 1, 2] }
  def reorder
    ids = params[:ids]
    return render json: { error: "ids requis" }, status: :bad_request unless ids.is_a?(Array)

    ids.each_with_index do |id, idx|
      @program_day.program_exercises.where(id: id).update_all(position: idx)
    end
    render json: { reordered: true }
  end

  # PATCH /api/v1/workout_programs/:workout_program_id/program_days/:program_day_id/program_exercises/:id/move
  # Body: { target_day_id:, position: }
  def move
    target_day = @program.program_days.find(params[:target_day_id])
    new_position = params[:position].to_i

    old_day = @program_day
    @program_exercise.update!(program_day: target_day, position: new_position)

    # Repack positions on source day
    old_day.program_exercises.where.not(id: @program_exercise.id).order(:position).each_with_index do |pe, idx|
      pe.update_column(:position, idx)
    end

    # Repack positions on target day
    target_day.program_exercises.where.not(id: @program_exercise.id).order(:position).each_with_index do |pe, idx|
      adjusted = idx < new_position ? idx : idx + 1
      pe.update_column(:position, adjusted)
    end

    render json: program_exercise_json(@program_exercise.reload)
  end

  private

  def set_program
    @program = current_user.workout_programs.find(params[:workout_program_id])
  end

  def set_program_day
    @program_day = @program.program_days.find(params[:program_day_id])
  end

  def set_program_exercise
    @program_exercise = @program_day.program_exercises.find(params[:id])
  end

  def program_exercise_params
    params.permit(:exercise_id, :sets, :reps_target, :weight_target, :rest_seconds, :notes)
  end

  def program_exercise_json(pe)
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
  end
end
