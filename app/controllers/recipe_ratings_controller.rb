class RecipeRatingsController < ApplicationController
  before_action :set_recipe
  before_action :set_rating, only: [:update, :destroy]

  def create
    @rating = @recipe.recipe_ratings.find_or_initialize_by(user: current_user)
    if @rating.update(rating_params)
      redirect_to @recipe, notice: t("controllers.recipe_ratings.created")
    else
      redirect_to @recipe
    end
  end

  def update
    if @rating.update(rating_params)
      redirect_to @recipe, notice: t("controllers.recipe_ratings.updated")
    else
      redirect_to @recipe
    end
  end

  def destroy
    @rating.destroy
    redirect_to @recipe, notice: t("controllers.recipe_ratings.destroyed")
  end

  private

  def set_recipe
    @recipe = current_user.recipes.find(params[:recipe_id])
  end

  def set_rating
    @rating = @recipe.recipe_ratings.find_by(user: current_user)
    redirect_to @recipe unless @rating
  end

  def rating_params
    params.require(:recipe_rating).permit(:rating, :comment)
  end
end
