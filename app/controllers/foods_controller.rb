class FoodsController < ApplicationController
  before_action :set_food, only: [:edit, :update, :destroy, :duplicate, :toggle_favorite, :toggle_pantry]

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

    if params[:in_stock] == "true"
      @foods = @foods.where(in_pantry: true)
      @filtering_in_stock = true
    end

    if params[:out_of_stock] == "true"
      @foods = @foods.where(in_pantry: false)
      @filtering_out_of_stock = true
    end

    if params[:label_id].present?
      @foods = @foods.where(id: current_user.foods.joins(:food_labels).where(food_labels: { id: params[:label_id] }).select(:id))
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
    @missing_count = current_user.foods.where(in_pantry: false).count
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

  def bulk_pantry
    scope = current_user.foods
    scope = scope.where(favorite: true) if params[:favorites] == "true"
    scope = scope.where(in_pantry: true) if params[:in_stock] == "true"
    scope = scope.where(in_pantry: false) if params[:out_of_stock] == "true"
    scope = scope.joins(:food_labels).where(food_labels: { id: params[:label_id] }) if params[:label_id].present?
    scope.update_all(in_pantry: params[:status] == "true")
    notice = params[:status] == "true" ? t("controllers.foods.bulk_pantry_in_stock") : t("controllers.foods.bulk_pantry_out_of_stock")
    redirect_to foods_path(
      label_id: params[:label_id].presence,
      favorites: params[:favorites].presence,
      in_stock: params[:in_stock].presence,
      out_of_stock: params[:out_of_stock].presence
    ), notice: notice
  end

  def add_missing_to_shopping_list
    missing = current_user.foods.where(in_pantry: false).order(:name)

    if missing.empty?
      redirect_to foods_path, notice: t("controllers.foods.no_missing_foods")
      return
    end

    list = current_user.shopping_lists.order(created_at: :asc).first_or_create!(
      name: t("views.shopping_lists.default_name")
    )
    missing.each do |food|
      list.add_or_merge_item(
        food:     food,
        name:     food.name,
        category: food.category
      )
    end
    redirect_to foods_path, notice: t("controllers.foods.missing_added", count: missing.size)
  end

  def toggle_favorite
    @food.update!(favorite: !@food.favorite)
    @usage_counts = DayFood.where(food_id: @food.id).group(:food_id).count
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to foods_path }
    end
  end

  def toggle_pantry
    @food.update!(in_pantry: !@food.in_pantry)
    @usage_counts = DayFood.where(food_id: @food.id).group(:food_id).count
    @missing_count = current_user.foods.where(in_pantry: false).count
    @filtering_in_stock = params[:filter_in_stock] == "true"
    @filtering_out_of_stock = params[:filter_out_of_stock] == "true"
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
    params.require(:food).permit(:name, :brand, :fats, :carbs, :sugars, :proteins, :calories, :category, food_label_ids: [])
  end
end
