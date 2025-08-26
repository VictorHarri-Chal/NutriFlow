class RecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [:show, :edit, :update, :destroy]

  def index
    @recipes = current_user.recipes.includes(recipe_items: :food).order(:name)

    if params[:query].present?
      @recipes = @recipes.search_by_name(params[:query])
    end
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

  private

  def set_recipe
    @recipe = current_user.recipes.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(
      :name, :instructions,
      recipe_items_attributes: [:id, :food_id, :quantity, :_destroy]
    )
  end
end
