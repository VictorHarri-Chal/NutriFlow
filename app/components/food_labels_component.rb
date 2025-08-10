class FoodLabelsComponent < ApplicationComponent
  def initialize(food:)
    @food = food
  end

  private

  attr_reader :food
end
