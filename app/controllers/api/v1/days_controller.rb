class Api::V1::DaysController < Api::V1::BaseController
  before_action :set_day, only: [:show, :update, :update_water, :update_steps, :copy_yesterday]

  def index
    scope = current_user.days
    scope = scope.where(date: params[:from]..params[:to]) if params[:from].present? && params[:to].present?
    scope = scope.where("date >= ?", params[:from]) if params[:from].present? && params[:to].blank?
    scope = scope.where("date <= ?", params[:to]) if params[:to].present? && params[:from].blank?
    @days = scope.order(date: :asc)
    render :index
  end

  def show
    render :show
  end

  def update
    if @day.update(day_params)
      render :show
    else
      render json: { errors: @day.errors }, status: :unprocessable_entity
    end
  end

  def update_water
    new_water = if params[:delta].present?
      [@day.water_ml + params[:delta].to_i, 0].max
    else
      params[:amount].to_i
    end
    @day.update!(water_ml: new_water)
    render json: { water_ml: @day.water_ml }
  end

  def update_steps
    steps = params[:steps].present? ? params[:steps].to_i : nil
    @day.update!(steps: steps)
    render json: {
      steps:          @day.steps,
      effective_steps: @day.effective_steps(current_user.profile)
    }
  end

  def copy_yesterday
    yesterday = current_user.days.find_by(date: @day.date - 1)
    unless yesterday
      render json: { error: "Aucun jour à copier." }, status: :not_found
      return
    end

    ActiveRecord::Base.transaction do
      yesterday.day_foods.includes(:food).each do |df|
        @day.day_foods.create!(
          food:             df.food,
          quantity:         df.quantity,
          day_food_group_id: df.day_food_group_id
        )
      end
      yesterday.day_recipes.includes(:recipe).each do |dr|
        @day.day_recipes.create!(
          recipe:             dr.recipe,
          quantity:           dr.quantity,
          use_recipe_quantity: dr.use_recipe_quantity,
          day_food_group_id:  dr.day_food_group_id
        )
      end
    end

    @day.reload
    render :show
  end

  private

  def set_day
    @day = current_user.days.find_or_create_by!(date: params[:date])
  end

  def day_params
    params.permit(:note, :energy_level, :mood, :sleep_quality)
  end
end
