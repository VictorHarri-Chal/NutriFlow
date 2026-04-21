class WorkoutProgramsController < ApplicationController
  before_action :set_program, only: [:show, :edit, :update, :destroy, :activate]

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

  private

  def set_program
    @program = current_user.workout_programs.find(params[:id])
  end

  def program_params
    params.require(:workout_program).permit(:name, :split_type)
  end
end
