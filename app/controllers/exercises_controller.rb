class ExercisesController < ApplicationController
  before_action :set_custom_exercise, only: [:edit, :update, :destroy]

  def index
    if params[:source] == "favorites"
      base = current_user.favorited_exercises.accessible_to(current_user)
    elsif params[:source] == "custom"
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

    @body_parts        = Exercise.body_parts
    @equipments        = Exercise.equipments
    @favorited_ids     = current_user.exercise_favorites.pluck(:exercise_id).to_set

    @pagy, @exercises = pagy(@exercises.with_attached_image.order(:name), items: 15)
  end

  def show
    @exercise     = Exercise.accessible_to(current_user).find(params[:id])
    @is_favorited = current_user.exercise_favorites.exists?(exercise: @exercise)
  end

  def search
    exercises = Exercise.accessible_to(current_user)
    if params[:query].present?
      exercises = exercises.search_by_name(params[:query])
    else
      exercises = exercises.order(:name)
    end
    exercises = exercises.limit(10)

    favorited_ids = current_user.exercise_favorites.pluck(:exercise_id).to_set

    render json: exercises.map { |e|
      key = e.body_part&.gsub(" ", "_")
      {
        id:               e.id,
        name:             e.name,
        body_part_label:  I18n.t("views.exercises.body_parts.#{key}", default: e.body_part&.capitalize.to_s),
        favorite:         favorited_ids.include?(e.id)
      }
    }
  end

  # GET /exercises/recents.json — last 8 distinct exercises used in workout sets by the user
  def recents
    exercise_ids = WorkoutSet
      .joins(workout_session: :day)
      .where(days: { user_id: current_user.id })
      .order("workout_sets.created_at DESC")
      .pluck(:exercise_id)
      .uniq
      .first(8)

    exercises = Exercise.where(id: exercise_ids).index_by(&:id)
    favorited_ids = current_user.exercise_favorites.pluck(:exercise_id).to_set

    ordered = exercise_ids.filter_map { |id| exercises[id] }

    render json: ordered.map { |e|
      key = e.body_part&.gsub(" ", "_")
      {
        id:               e.id,
        name:             e.name,
        body_part_label:  I18n.t("views.exercises.body_parts.#{key}", default: e.body_part&.capitalize.to_s),
        favorite:         favorited_ids.include?(e.id)
      }
    }
  end

  # GET /exercises/favorites.json — used by exercise combobox to show favorites upfront
  def favorites
    exercises = current_user.favorited_exercises.accessible_to(current_user).order(:name)

    render json: exercises.map { |e|
      key = e.body_part&.gsub(" ", "_")
      {
        id:               e.id,
        name:             e.name,
        body_part_label:  I18n.t("views.exercises.body_parts.#{key}", default: e.body_part&.capitalize.to_s),
        favorite:         true
      }
    }
  end

  def last_performance
    exercise = Exercise.accessible_to(current_user).find(params[:id])

    # All-time max weight for PR detection.
    # exclude_session_id: when editing a session, exclude it so the current
    # sets don't inflate the max and break the "val > max" comparison.
    exclude_session_id = params[:exclude_session_id].presence&.to_i
    all_time_max_scope = WorkoutSet
                           .joins(workout_session: :day)
                           .where(exercise_id: exercise.id, days: { user_id: current_user.id })
    all_time_max_scope = all_time_max_scope.where.not(workout_session_id: exclude_session_id) if exclude_session_id
    all_time_max = all_time_max_scope.maximum(:weight_kg)&.to_f || 0

    # Use a subquery to avoid JOIN duplication (multiple sets per session would
    # cause duplicate rows and .limit(2) would return the same session twice).
    # Also exclude the session being edited so "last performance" shows the previous session.
    sessions_scope = WorkoutSession
                       .joins(:day)
                       .where(id: WorkoutSet.where(exercise_id: exercise.id).select(:workout_session_id))
                       .where(days: { user_id: current_user.id })
                       .order("days.date DESC")
    sessions_scope = sessions_scope.where.not(id: exclude_session_id) if exclude_session_id
    sessions = sessions_scope.limit(2).to_a

    if sessions.any?
      last = sessions.first
      prev = sessions.second

      last_sets  = last.workout_sets.where(exercise_id: exercise.id).order(:position)
      prev_sets  = prev&.workout_sets&.where(exercise_id: exercise.id)

      last_max   = last_sets.maximum(:weight_kg)&.to_f || 0
      prev_max   = prev_sets&.maximum(:weight_kg)&.to_f || 0
      delta      = (last_max > 0 && prev_max > 0) ? (last_max - prev_max).round(2) : nil

      render json: {
        date:         I18n.l(last.day.date, format: :short),
        sets:         last_sets.map { |s| { weight_kg: s.weight_kg, reps: s.reps } },
        delta:        delta,
        all_time_max: all_time_max
      }
    else
      render json: { sets: [], all_time_max: all_time_max }
    end
  end

  def toggle_favorite
    exercise = Exercise.accessible_to(current_user).find(params[:id])
    fav = current_user.exercise_favorites.find_by(exercise: exercise)

    if fav
      fav.destroy
      favorited = false
    else
      current_user.exercise_favorites.create!(exercise: exercise)
      favorited = true
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "favorite_btn_#{exercise.id}",
            partial: "exercises/favorite_button",
            locals:  { exercise: exercise, favorited: favorited }
          )
        ]
      end
      format.html { redirect_back fallback_location: exercises_path }
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
      @exercise.image.purge if params[:exercise][:remove_image] == "1"
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
