class WorkoutProgramsController < ApplicationController
  before_action :set_program, only: [:show, :edit, :update, :destroy, :activate, :duplicate]

  def index
    @programs = current_user.workout_programs.includes(:program_days).order(created_at: :asc)
  end

  def show
    @program_days = @program.program_days.includes(program_exercises: :exercise)
  end

  def new
    @program = current_user.workout_programs.build
  end

  def create
    is_first = !current_user.workout_programs.exists?
    @program = current_user.workout_programs.build(program_params)
    @program.is_active = is_first
    if @program.save
      redirect_to @program, notice: t("controllers.workout_programs.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @program.update(program_params)
      redirect_to @program, notice: t("controllers.workout_programs.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @program.destroy
    redirect_to workout_programs_path, notice: t("controllers.workout_programs.destroyed")
  end

  def activate
    @program.activate!
    redirect_back_or_to @program, notice: t("controllers.workout_programs.activated")
  end

  def duplicate
    copy = @program.dup
    copy.name       = t("controllers.workout_programs.duplicate_name", name: @program.name)
    copy.is_active  = false
    copy.save!

    @program.program_days.includes(:program_exercises).each do |source_day|
      target_day = copy.program_days.find_by!(day_of_week: source_day.day_of_week)
      target_day.update!(
        name:             source_day.name,
        duration_minutes: source_day.duration_minutes,
        notes:            source_day.notes
      )
      source_day.program_exercises.each do |pe|
        target_day.program_exercises.create!(
          exercise_id:   pe.exercise_id,
          sets:          pe.sets,
          reps_target:   pe.reps_target,
          weight_target: pe.weight_target,
          rest_seconds:  pe.rest_seconds,
          notes:         pe.notes,
          position:      pe.position
        )
      end
    end

    redirect_to copy, notice: t("controllers.workout_programs.duplicated")
  end

  private

  def set_program
    @program = current_user.workout_programs.find(params[:id])
  end

  def program_params
    params.require(:workout_program).permit(:name, :split_type)
  end
end
