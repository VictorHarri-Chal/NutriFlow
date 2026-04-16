class FoodsController < ApplicationController
  before_action :set_food, only: [:edit, :update, :destroy, :duplicate, :toggle_favorite]

  def index
    @food_labels = current_user.food_labels.order(:name)
    @q = current_user.foods.includes(:food_labels).ransack(params[:q])
    @foods = @q.result

    if params[:query].present?
      @foods = @foods.search_by_name(params[:query])
    end

    if params[:favorites] == "true"
      @foods = @foods.where(favorite: true)
      @filtering_favorites = true
    end

    if params[:label_id].present?
      @foods = @foods.joins(:food_labels).where(food_labels: { id: params[:label_id] })
      @selected_label_id = params[:label_id].to_i
    end

    if params[:full_result] == "true"
      @foods = @foods.order(created_at: :desc)
      @pagy = nil
    else
      @pagy, @foods = pagy(@foods.order(created_at: :desc), items: 10)
    end

    food_ids = @foods.pluck(:id)
    @usage_counts = food_ids.any? ? DayFood.where(food_id: food_ids).group(:food_id).count : {}
  end

  def new
    @food = current_user.foods.build
    @food_labels = current_user.food_labels
  end

  def create
    @food = current_user.foods.build(food_params)
    if @food.save
      redirect_to foods_path, notice: t("controllers.foods.created")
    else
      @food_labels = current_user.food_labels
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @food_labels = current_user.food_labels
  end

  def update
    if @food.update(food_params)
      redirect_to foods_path, notice: t("controllers.foods.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @food.destroy
    redirect_to foods_path, notice: t("controllers.foods.destroyed")
  end

  def toggle_favorite
    @food.update!(favorite: !@food.favorite)
    @usage_counts = DayFood.where(food_id: @food.id).group(:food_id).count
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to foods_path }
    end
  end

  def duplicate
    copy = @food.dup
    copy.name = t("controllers.foods.duplicate_name", name: @food.name)
    if copy.save
      redirect_to edit_food_path(copy), notice: t("controllers.foods.duplicated")
    else
      redirect_to foods_path, alert: t("controllers.foods.duplicate_error")
    end
  end

  private

  def set_food
    @food = current_user.foods.find(params[:id])
  end

  def food_params
    params.require(:food).permit(:name, :brand, :fats, :carbs, :sugars, :proteins, :calories, food_label_ids: [])
  end
end
