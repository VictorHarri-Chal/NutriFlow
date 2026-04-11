class RecipesController < ApplicationController
  before_action :set_recipe, only: [:show, :edit, :update, :destroy, :duplicate]

  def index
    @recipes = current_user.recipes.includes(recipe_items: :food, recipe_ratings: [])

    if params[:query].present?
      @recipes = @recipes.search_by_name(params[:query])
    else
      @recipes = @recipes.order(sort_order)
    end

    @pagy, @recipes = pagy(@recipes, items: 12)
  end

  def show
  end

  def new
    @recipe = current_user.recipes.new
    @recipe.recipe_items.build
  end

  def create
    @recipe = current_user.recipes.new(recipe_params)

    if @recipe.save
      redirect_to recipes_path
    else
      @recipe.recipe_items.build if @recipe.recipe_items.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to recipe_path(@recipe)
    else
      @recipe.recipe_items.build if @recipe.recipe_items.empty?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    redirect_to recipes_path
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

  private

  def set_recipe
    @recipe = current_user.recipes.includes(recipe_items: :food, recipe_ratings: [], recipe_comments: []).find(params[:id])
  end

  def sort_order
    case params[:sort]
    when "newest" then { created_at: :desc }
    when "oldest" then { created_at: :asc }
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
