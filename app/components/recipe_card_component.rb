# frozen_string_literal: true

class RecipeCardComponent < ApplicationComponent
  def initialize(recipe:)
    @recipe = recipe
  end

  private

  attr_reader :recipe
end
