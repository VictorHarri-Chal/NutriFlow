# frozen_string_literal: true

class RecipeCommentsComponent < ApplicationComponent
  def initialize(recipe:, current_user:)
    @recipe = recipe
    @current_user = current_user
    @comments = if recipe.recipe_comments.loaded?
      recipe.recipe_comments.sort_by { |c| -c.created_at.to_i }
    else
      recipe.recipe_comments.ordered
    end
  end

  private

  attr_reader :recipe, :current_user, :comments
end
