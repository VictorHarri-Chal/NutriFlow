module Ui
  class EmptyStateComponent < ApplicationComponent
    renders_one :cta

    SIZES = {
      lg: { wrap: "py-16 px-6", circle: "w-12 h-12", icon: "text-lg",  title: "text-base", hint: "text-sm max-w-sm" },
      md: { wrap: "py-10 px-4", circle: "w-12 h-12", icon: "text-lg",  title: "text-sm",   hint: "text-xs max-w-xs" },
      sm: { wrap: "py-8 px-4",  circle: "w-10 h-10", icon: "text-base", title: "text-sm",   hint: "text-xs max-w-xs" }
    }.freeze

    def initialize(icon:, title:, hint: nil, size: :lg)
      @icon = icon; @title = title; @hint = hint; @size = SIZES.fetch(size)
    end

    attr_reader :icon, :title, :hint, :size
  end
end
