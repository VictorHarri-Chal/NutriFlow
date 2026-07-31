# frozen_string_literal: true

class RecipeCardComponent < ApplicationComponent
  with_collection_parameter :recipe

  def initialize(recipe:, current_user:)
    @recipe = recipe
    @current_user = current_user
  end

  private

  attr_reader :recipe, :current_user

  def user_rating
    recipe.rating_for(current_user)
  end

end
