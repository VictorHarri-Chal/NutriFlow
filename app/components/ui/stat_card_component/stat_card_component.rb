module Ui
  class StatCardComponent < ApplicationComponent
    # Optional third line under the value (e.g. a goal-comparison with a
    # conditional colour). Omit it for a plain label + value card.
    renders_one :sub

    def initialize(label:, value:, unit: nil, value_color: "text-ink-primary")
      @label = label
      @value = value
      @unit = unit
      @value_color = value_color
    end

    attr_reader :label, :value, :unit, :value_color
  end
end
