class FoodsController < ApplicationController
  before_action :set_food, only: [:show, :edit, :update, :destroy, :duplicate, :toggle_favorite, :toggle_pantry]

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

    if params[:category].present?
      @foods = @foods.where(category: params[:category])
      @selected_category = params[:category]
    end

    if params[:source].present?
      @foods = @foods.where(source: params[:source])
      @selected_source = params[:source]
    end

    if params[:sort_usages].present?
      dir = params[:sort_usages] == "asc" ? "ASC" : "DESC"
      @foods = @foods.reorder(Arel.sql("(SELECT COUNT(*) FROM day_foods WHERE day_foods.food_id = foods.id) #{dir}"))
    elsif params.dig(:q, :s).blank?
      @foods = @foods.order(created_at: :desc)
    end

    if params[:full_result] == "true"
      @pagy = nil
    else
      @pagy, @foods = pagy(@foods, items: 10)
    end

    food_ids = @foods.pluck(:id)
    @usage_counts = food_ids.any? ? DayFood.where(food_id: food_ids).group(:food_id).count : {}
    @missing_count = current_user.foods.where(in_pantry: false).count
  end

  def show
    @usage_count = @food.day_foods.count
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
      @food_labels = current_user.food_labels
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

    list = current_user.active_shopping_list
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

  def search_import
    query = params[:q].to_s.strip
    return render json: { products: [] } if query.length < 2

    products = CiqualFood.search_by_name(query).limit(15).map do |f|
      { source: "ciqual", name: f.name, brand: nil, category: f.food_group,
        calories: f.calories.to_f.round(1), proteins: f.proteins.to_f.round(1),
        carbs: f.carbs.to_f.round(1), fats: f.fats.to_f.round(1),
        sugars: f.sugars.to_f.round(1),
        fiber: f.fiber&.to_f&.round(1), saturated_fat: f.saturated_fat&.to_f&.round(1),
        salt: f.salt&.to_f&.round(1), micronutrients: f.micronutrients.presence || {} }
    end

    render json: { products: }
  end

  def barcode_import
    code = params[:code].to_s.gsub(/\D/, "")
    return render json: { error: t("controllers.foods.barcode_not_found") }, status: :not_found unless [8, 12, 13].include?(code.length)

    if (existing = current_user.foods.find_by(off_id: code))
      return render json: { existing_food: { id: existing.id } }
    end

    product = Rails.cache.fetch("off_barcode:#{code}", expires_in: 24.hours) do
      OpenFoodFactsService.by_barcode(code)
    end

    if product
      render json: { product: product.merge(source: "off") }
    else
      render json: { error: t("controllers.foods.barcode_not_found") }, status: :not_found
    end
  end

  def duplicate
    copy = @food.dup
    copy.name = unique_copy_name
    if copy.save
      copy.food_labels = @food.food_labels
      redirect_to edit_food_path(copy), notice: t("controllers.foods.duplicated")
    else
      redirect_to foods_path, alert: t("controllers.foods.duplicate_error")
    end
  end

  private

  def unique_copy_name
    base = t("controllers.foods.duplicate_name", name: @food.name)
    taken = current_user.foods
      .where("LOWER(name) = LOWER(?) OR LOWER(name) LIKE LOWER(?)",
             base, "#{ActiveRecord::Base.sanitize_sql_like(base)} (%)")
      .pluck(Arel.sql("LOWER(name)")).to_set
    return base unless taken.include?(base.downcase)
    n = 2
    n += 1 while taken.include?("#{base.downcase} (#{n})")
    "#{base} (#{n})"
  end

  def set_food
    @food = current_user.foods.find(params[:id])
  end

  def food_params
    params.require(:food).permit(
      :name, :brand, :fats, :carbs, :sugars, :proteins, :calories, :category,
      :off_id, :nutriscore_grade, :nova_group, :source,
      :fiber, :saturated_fat, :salt, :ecoscore_grade,
      :allergens_raw, :traces_raw, :additives_raw, :labels_raw, :ingredients_text,
      :micronutrients,
      food_label_ids: [],
      allergens: [],
      traces: [],
      additives: [],
      labels: []
    ).tap do |p|
      %i[allergens traces additives labels].each do |field|
        raw_key = :"#{field}_raw"
        if p[raw_key].present?
          p[field] = p.delete(raw_key).split(",").map(&:strip).reject(&:blank?)
        else
          p.delete(raw_key)
        end
      end
      # micronutrients arrives as a JSON string from the hidden field
      if p[:micronutrients].is_a?(String)
        begin
          p[:micronutrients] = JSON.parse(p[:micronutrients]).transform_keys(&:to_s).presence || {}
        rescue JSON::ParserError
          p[:micronutrients] = {}
        end
      end
    end
  end
end
