module Ui
  class ProgressBarComponent < ApplicationComponent
    def initialize(percent:, color: "bg-brand", height: "h-4")
      @percent = [[percent.to_f, 0].max, 100].min
      @color = color; @height = height
    end

    attr_reader :percent, :color, :height
  end
end
