module Ui
  # Minimal "not enough data" placeholder for a chart/graph slot: a dashed box
  # with a bare (un-circled) icon and one or two lines of muted text. Distinct
  # from EmptyStateComponent (which has a circle icon + CTA and is for page/section
  # zero-states). `height` sets the box height (e.g. "h-40", "py-10", "flex-1 min-h-0").
  class ChartPlaceholderComponent < ApplicationComponent
    def initialize(icon:, text:, subtext: nil, height: "py-10")
      @icon = icon
      @text = text
      @subtext = subtext
      @height = height
    end

    attr_reader :icon, :text, :subtext, :height
  end
end
