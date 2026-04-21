class RecipeRatingsController < ApplicationController
  before_action :set_recipe
  before_action :set_rating, only: [:destroy]

  def create
    @rating = @recipe.recipe_ratings.find_or_initialize_by(user: current_user)
    is_new  = @rating.new_record?
    if @rating.update(rating_params)
      key = is_new ? "controllers.recipe_ratings.created" : "controllers.recipe_ratings.updated"
      redirect_to @recipe, notice: t(key)
    else
      redirect_to @recipe, alert: t("controllers.recipe_ratings.error")
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
