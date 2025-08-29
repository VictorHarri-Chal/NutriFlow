class RecipeCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe
  before_action :set_comment, only: [:update, :destroy]
  before_action :ensure_recipe_owner, only: [:create, :update, :destroy]

  def create
    @comment = @recipe.recipe_comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @recipe
    else
      redirect_to @recipe
    end
  end

  def update
    if @comment.update(comment_params)
      redirect_to @recipe
    else
      redirect_to @recipe
    end
  end

  def destroy
    @comment.destroy
    redirect_to @recipe
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end

  def set_comment
    @comment = @recipe.recipe_comments.find(params[:id])
  end

  def ensure_recipe_owner
    unless @recipe.user == current_user
      redirect_to @recipe
    end
  end

  def comment_params
    params.require(:recipe_comment).permit(:content)
  end
end
