# frozen_string_literal: true

class RecipeRatingFormComponent < ApplicationComponent
  def initialize(recipe:, current_user:)
    @recipe = recipe
    @current_user = current_user
    @current_user_rating = if recipe.recipe_ratings.loaded?
      recipe.recipe_ratings.detect { |r| r.user_id == current_user.id }
    else
      recipe.recipe_ratings.find_by(user: current_user)
    end
    @existing_rating = @current_user_rating&.rating || 0
    @existing_comment = @current_user_rating&.comment
  end

  private

  attr_reader :recipe, :current_user, :current_user_rating, :existing_rating, :existing_comment
end
