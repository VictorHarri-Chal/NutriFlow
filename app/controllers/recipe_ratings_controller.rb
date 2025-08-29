class RecipeRatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe
  before_action :ensure_recipe_owner, only: [:create, :update, :destroy]
  before_action :set_rating, only: [:update, :destroy]

  def create
    if @recipe.recipe_rating
      if @recipe.recipe_rating.update(rating_params)
        redirect_to @recipe
      else
        redirect_to @recipe
      end
    else
      # Créer un nouveau rating
      @rating = @recipe.build_recipe_rating(rating_params)
      @rating.user = current_user

      if @rating.save
        redirect_to @recipe
      else
        redirect_to @recipe
      end
    end
  end

  def update
    if @rating.update(rating_params)
      redirect_to @recipe
    else
      redirect_to @recipe
    end
  end

  def destroy
    @rating.destroy
    redirect_to @recipe
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end

  def set_rating
    @rating = @recipe.recipe_rating
    redirect_to @recipe unless @rating
  end

  def ensure_recipe_owner
    unless @recipe.user == current_user
      redirect_to @recipe
    end
  end

  def rating_params
    params.require(:recipe_rating).permit(:rating, :comment)
  end
end
