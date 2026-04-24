class RecipesController < ApplicationController
  before_action :set_recipe, only: [:show, :edit, :update, :destroy, :duplicate, :toggle_favorite, :add_to_shopping_list]

  def index
    @recipes = current_user.recipes.includes(recipe_items: :food, recipe_ratings: [])
    @source  = params[:source]

    @recipes = @recipes.where(favorite: true) if @source == "favorites"

    if params[:query].present?
      @recipes = @recipes.search_by_name(params[:query])
      @pagy, @recipes = pagy(@recipes, items: 12)
    elsif %w[calories proteins].include?(params[:sort])
      sorted = @recipes.to_a.sort_by { |r| r.public_send(:"total_#{params[:sort]}") }
      sorted.reverse! unless params[:direction] == "asc"
      @pagy, @recipes = pagy_array(sorted, items: 12)
    else
      @recipes = @recipes.order(sort_order)
      @pagy, @recipes = pagy(@recipes, items: 12)
    end
  end

  def show
  end

  def new
    @recipe = current_user.recipes.new
  end

  def create
    @recipe = current_user.recipes.new(recipe_params)

    if @recipe.save
      redirect_to recipes_path, notice: t("controllers.recipes.created")
    else
      @recipe.recipe_items.build if @recipe.recipe_items.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to recipe_path(@recipe), notice: t("controllers.recipes.updated")
    else
      @recipe.recipe_items.build if @recipe.recipe_items.empty?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    redirect_to recipes_path, notice: t("controllers.recipes.destroyed")
  end

  def duplicate
    copy = Recipe.new(
      user: current_user,
      name: t("controllers.recipes.duplicate_name", name: @recipe.name),
      instructions: @recipe.instructions
    )
    @recipe.recipe_items.each do |item|
      copy.recipe_items.build(food: item.food, quantity: item.quantity)
    end

    if copy.save
      redirect_to recipe_path(copy), notice: t("controllers.recipes.duplicated")
    else
      redirect_to recipes_path, alert: t("controllers.recipes.duplicate_error")
    end
  end

  def toggle_favorite
    @recipe.update!(favorite: !@recipe.favorite)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: recipes_path }
    end
  end

  def add_to_shopping_list
    smart = params[:smart] != "false"
    items = @recipe.recipe_items.includes(:food)
    items = items.select { |i| !i.food.in_pantry } if smart

    if smart && items.empty?
      @nothing_missing = true
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to recipe_path(@recipe), notice: t("views.shopping_lists.nothing_missing") }
      end
      return
    end

    @shopping_list = current_user.shopping_lists.order(created_at: :asc).first_or_create!(
      name: t("views.shopping_lists.default_name")
    )

    items.each do |item|
      @shopping_list.add_or_merge_item(
        food:     item.food,
        name:     item.food.name,
        quantity: "#{item.quantity.to_i} g",
        category: item.food.category
      )
    end

    @added_count = items.size
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @shopping_list, notice: t("views.shopping_lists.items_added", count: @added_count) }
    end
  end

  private

  def set_recipe
    @recipe = current_user.recipes.includes(recipe_items: :food, recipe_ratings: []).find(params[:id])
  end

  def sort_order
    dir = params[:direction] == "desc" ? :desc : :asc
    case params[:sort]
    when "date" then { created_at: params[:direction] == "asc" ? :asc : :desc }
    when "name" then { name: dir }
    else { name: :asc }
    end
  end

  def recipe_params
    params.require(:recipe).permit(
      :name, :instructions,
      recipe_items_attributes: [:id, :food_id, :quantity, :_destroy]
    )
  end
end
