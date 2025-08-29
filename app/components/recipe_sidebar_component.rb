# frozen_string_literal: true

class RecipeSidebarComponent < ApplicationComponent
  def initialize(recipe:, current_user:)
    @recipe = recipe
    @current_user = current_user
  end

  private

  attr_reader :recipe, :current_user
end
