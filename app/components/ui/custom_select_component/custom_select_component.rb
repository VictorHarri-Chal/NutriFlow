module Ui
  class CustomSelectComponent < ApplicationComponent
    def initialize(name:, choices:, selected: nil, label: nil, width: "w-full", dropdown_max_h: "max-h-60", **select_options)
      @name = name; @choices = choices; @selected = selected; @label = label
      @width = width; @dropdown_max_h = dropdown_max_h; @select_options = select_options
    end

    attr_reader :name, :choices, :selected, :label, :width, :dropdown_max_h, :select_options

    def selected_label
      pair = choices.find { |_l, v| v.to_s == selected.to_s }
      pair ? pair.first : choices.first&.first
    end
  end
end
