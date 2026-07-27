module Ui
  # Card / section header: brand icon + title, optional description below,
  # optional right-aligned actions slot (period pills, a select…).
  #
  #   render Ui::SectionHeaderComponent.new(icon: "fa-sliders", title: "…",
  #                                         description: "…", size: :base)
  class SectionHeaderComponent < ApplicationComponent
    renders_one :actions

    TITLE_SIZES = { base: "text-base", sm: "text-sm" }.freeze

    def initialize(icon:, title:, description: nil, size: :base, **options)
      @icon = icon; @title = title; @description = description; @size = size; @options = options
    end

    attr_reader :icon, :title, :description

    def root_class
      ["flex items-center justify-between gap-3", @options[:class]].compact.join(" ")
    end

    def title_size
      TITLE_SIZES.fetch(@size)
    end
  end
end
