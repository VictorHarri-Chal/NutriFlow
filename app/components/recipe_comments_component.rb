# frozen_string_literal: true

class RecipeCommentsComponent < ApplicationComponent
  def initialize(recipe:, current_user:)
    @recipe = recipe
    @current_user = current_user
    @comments = recipe.recipe_comments.ordered
  end

  private

  attr_reader :recipe, :current_user, :comments
end
