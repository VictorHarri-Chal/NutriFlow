# frozen_string_literal: true

class RecipeRatingFormComponent < ApplicationComponent
  def initialize(recipe:, current_user:)
    @recipe = recipe
    @current_user = current_user
    @existing_rating = recipe.rating
    @existing_comment = recipe.rating_comment
  end

  private

  attr_reader :recipe, :current_user, :existing_rating, :existing_comment
end
