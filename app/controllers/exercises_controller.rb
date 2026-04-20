class ExercisesController < ApplicationController
  before_action :set_custom_exercise, only: [:edit, :update, :destroy]

  def index
    if params[:source] == "custom"
      base = Exercise.for_user(current_user)
    else
      gif_fetch_started = Exercise.global.where.not(gif_status: nil).exists?
      base = gif_fetch_started ? Exercise.accessible_to(current_user).visible : Exercise.accessible_to(current_user)
    end

    @exercises = base
    @exercises = @exercises.search_by_name(params[:query])    if params[:query].present?
    @exercises = @exercises.by_body_part(params[:body_part])  if params[:body_part].present?
    @exercises = @exercises.by_equipment(params[:equipment])  if params[:equipment].present?
    @exercises = @exercises.where(difficulty: params[:difficulty]) if params[:difficulty].present?

    @body_parts = Exercise.body_parts
    @equipments = Exercise.equipments

    @pagy, @exercises = pagy(@exercises.with_attached_image.order(:name), items: 12)
  end

  def show
    @exercise = Exercise.accessible_to(current_user).find(params[:id])
  end

  def search
    exercises = Exercise.accessible_to(current_user)
    if params[:query].present?
      exercises = exercises.search_by_name(params[:query])
    else
      exercises = exercises.order(:name)
    end
    exercises = exercises.limit(10)

    render json: exercises.map { |e|
      key = e.body_part&.gsub(" ", "_")
      {
        id:               e.id,
        name:             e.name,
        body_part_label:  I18n.t("views.exercises.body_parts.#{key}", default: e.body_part&.capitalize.to_s)
      }
    }
  end

  def last_performance
    exercise = Exercise.accessible_to(current_user).find(params[:id])

    last_session = WorkoutSession.joins(:day, :workout_sets)
                                 .where(days: { user_id: current_user.id })
                                 .where(workout_sets: { exercise_id: exercise.id })
                                 .order("days.date DESC")
                                 .first

    if last_session
      sets = last_session.workout_sets.where(exercise_id: exercise.id).order(:position)
      render json: {
        date: I18n.l(last_session.day.date, format: :short),
        sets: sets.map { |s| { weight_kg: s.weight_kg, reps: s.reps } }
      }
    else
      render json: { sets: [] }
    end
  end

  def new
    @exercise = Exercise.new
  end

  def create
    @exercise = Exercise.new(exercise_params)
    @exercise.custom_user_id = current_user.id
    @exercise.exercise_id    = "custom_#{current_user.id}_#{SecureRandom.hex(6)}"

    if @exercise.save
      redirect_to exercise_path(@exercise), notice: t("views.exercises.custom.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @exercise.update(exercise_params)
      redirect_to exercise_path(@exercise), notice: t("views.exercises.custom.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @exercise.destroy
    redirect_to exercises_path, notice: t("views.exercises.custom.flash.deleted")
  end

  private

  def set_custom_exercise
    @exercise = Exercise.for_user(current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to exercises_path, alert: t("views.exercises.custom.flash.not_found")
  end

  def exercise_params
    p = params.require(:exercise).permit(
      :name, :body_part, :equipment, :target_muscle,
      :category, :difficulty, :description, :instructions,
      :image, :secondary_muscles_raw
    )
    if p[:secondary_muscles_raw]
      p[:secondary_muscles] = p.delete(:secondary_muscles_raw)
                                .split(",").map(&:strip).reject(&:blank?)
    end
    p
  end
end
