module Ui
  class PanelComponent < ApplicationComponent
    def initialize(padding: "p-6", **options)
      @padding = padding; @options = options
    end

    def call
      extra_class = @options.delete(:class)
      tag.div(content, class: ["bg-surface-raised border border-surface-border/40 rounded-panel", @padding, extra_class].compact.join(" "), **@options)
    end
  end
end
