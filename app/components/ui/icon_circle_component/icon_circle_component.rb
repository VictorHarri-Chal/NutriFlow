module Ui
  # `icon` is a raw Font Awesome glyph string (e.g. "fa-user"), not a ui_icon
  # action — this renders arbitrary domain icons, not the canonical action set.
  class IconCircleComponent < ApplicationComponent
    SIZES = { sm: "w-8 h-8 text-sm", md: "w-12 h-12 text-lg", lg: "w-14 h-14 text-xl" }.freeze

    def initialize(icon:, size: :md, bg: "bg-surface-raised", color: "text-brand")
      @icon = icon; @size = SIZES.fetch(size); @bg = bg; @color = color
    end

    def call
      tag.div(tag.i(class: "fas #{@icon} #{@color}"), class: "#{@size} #{@bg} rounded-full flex items-center justify-center")
    end
  end
end
