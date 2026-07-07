class Api::V1::ExercisesController < Api::V1::BaseController
  include ExercisesHelper

  before_action :set_exercise, only: [:show, :update, :destroy, :favorite, :unfavorite, :last_performance]

  def index
    scope = Exercise.accessible_to(current_user)
    scope = scope.search_by_name(params[:query]) if params[:query].present?
    scope = scope.by_body_part(params[:body_part]) if params[:body_part].present?
    scope = scope.by_equipment(params[:equipment]) if params[:equipment].present?
    scope = scope.where(difficulty: params[:difficulty]) if params[:difficulty].present?
    scope = scope.order(:name)

    @pagy, @exercises = pagy(scope, items: 25)
    @favorited_ids = current_user.exercise_favorites.pluck(:exercise_id).to_set
    render :index
  end

  def show
    @is_favorited = current_user.exercise_favorites.exists?(exercise: @exercise)
    render :show
  end

  def create
    @exercise = Exercise.new(exercise_params.merge(
      custom_user_id: current_user.id,
      exercise_id:    SecureRandom.uuid
    ))
    if @exercise.save
      @is_favorited = false
      render :show, status: :created
    else
      render json: { errors: @exercise.errors }, status: :unprocessable_entity
    end
  end

  def update
    unless @exercise.custom_user_id == current_user.id
      render json: { error: "Not found" }, status: :not_found
      return
    end
    if @exercise.update(exercise_params)
      @is_favorited = current_user.exercise_favorites.exists?(exercise: @exercise)
      render :show
    else
      render json: { errors: @exercise.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    unless @exercise.custom_user_id == current_user.id
      render json: { error: "Not found" }, status: :not_found
      return
    end
    @exercise.destroy
    render json: {}, status: :no_content
  end

  def search
    scope = Exercise.accessible_to(current_user)
    scope = scope.search_by_name(params[:query]) if params[:query].present?
    @favorited_ids = current_user.exercise_favorites.pluck(:exercise_id).to_set
    exercises = scope.limit(20).map do |ex|
      {
        id:            ex.id,
        name:          ex.name,
        body_part:     ex.body_part,
        is_favorited:  @favorited_ids.include?(ex.id)
      }
    end
    render json: exercises
  end

  def favorites
    @pagy, @exercises = pagy(
      Exercise.accessible_to(current_user)
              .joins(:exercise_favorites)
              .where(exercise_favorites: { user_id: current_user.id })
              .order(:name),
      items: 25
    )
    @favorited_ids = @exercises.map(&:id).to_set
    render :index
  end

  def recents
    exercise_ids = WorkoutSet
      .joins(workout_session: { day: {} })
      .where(days: { user_id: current_user.id })
      .order("workout_sets.created_at DESC")
      .select(:exercise_id)
      .distinct
      .limit(8)
      .pluck(:exercise_id)

    exercises = Exercise.where(id: exercise_ids).index_by(&:id)
    @favorited_ids = current_user.exercise_favorites.pluck(:exercise_id).to_set
    ordered = exercise_ids.filter_map { |id| exercises[id] }
    render json: ordered.map { |ex|
      {
        id:           ex.id,
        name:         ex.name,
        body_part:    ex.body_part,
        is_favorited: @favorited_ids.include?(ex.id)
      }
    }
  end

  def favorite
    fav = current_user.exercise_favorites.find_or_create_by(exercise: @exercise)
    render json: { favorited: true, id: fav.id }
  end

  def unfavorite
    current_user.exercise_favorites.find_by(exercise: @exercise)&.destroy
    render json: { favorited: false }
  end

  def last_performance
    base = WorkoutSet
      .joins(workout_session: { day: {} })
      .where(
        days: { user_id: current_user.id },
        exercise_id: @exercise.id
      )

    base = base.where.not(workout_session_id: params[:exclude_session_id]) if params[:exclude_session_id].present?

    last_session_id = base.order("days.date DESC, workout_sets.created_at DESC")
                          .pick(Arel.sql("workout_sets.workout_session_id"))

    if last_session_id.nil?
      render json: nil
      return
    end

    last_sets = base.where(workout_session_id: last_session_id).order(:position)
    last_date  = WorkoutSession.joins(:day).where(id: last_session_id).pick("days.date")
    max_weight = last_sets.maximum(:weight_kg)
    all_time_max = base.maximum(:weight_kg)

    prev_max = base.where.not(workout_session_id: last_session_id).maximum(:weight_kg)
    delta_kg = prev_max.present? ? (max_weight.to_f - prev_max.to_f).round(2) : nil

    render json: {
      date:           last_date,
      sets:           last_sets.map { |s| { weight_kg: s.weight_kg, reps: s.reps } },
      delta_kg:       delta_kg,
      all_time_max_kg: all_time_max
    }
  end

  private

  def set_exercise
    @exercise = Exercise.accessible_to(current_user).find(params[:id])
  end

  def exercise_params
    params.permit(
      :name, :body_part, :equipment, :target_muscle, :category,
      :difficulty, :description, :instructions, :image,
      secondary_muscles: []
    )
  end
end
