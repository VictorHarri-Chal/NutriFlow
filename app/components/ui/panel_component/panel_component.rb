module Ui
  class PanelComponent < ApplicationComponent
    def initialize(padding: "p-6", **options)
      @padding = padding; @options = options
    end

    def call
      tag.div(content, class: ["bg-surface-raised border border-surface-border/40 rounded-panel", @padding].join(" "), **@options)
    end
  end
end
