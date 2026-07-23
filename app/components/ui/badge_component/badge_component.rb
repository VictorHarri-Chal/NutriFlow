module Ui
  class BadgeComponent < ApplicationComponent
    STATUS = {
      brand:   "bg-brand/15 text-brand border-brand/30",
      success: "bg-status-success/10 text-status-success border-status-success/30",
      warning: "bg-status-warning/10 text-status-warning border-status-warning/30",
      danger:  "bg-status-danger/10 text-status-danger border-status-danger/30",
      info:    "bg-status-info/10 text-status-info border-status-info/30",
      neutral: "bg-surface-hover/60 text-ink-muted border-surface-border/40"
    }.freeze
    BADGE_BASE = "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium border"
    PILL_BASE  = "inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-medium border transition-colors"
    PILL_ACTIVE   = "bg-brand/20 text-brand border-brand/50"
    PILL_INACTIVE = "bg-transparent text-ink-muted border-surface-border/40 hover:text-ink-primary hover:border-surface-border"

    def initialize(label, variant: :neutral, style: :badge, active: false, icon: nil, **options)
      @label = label; @variant = variant; @style = style; @active = active; @icon = icon; @options = options
    end

    def call
      extra_class = @options.delete(:class)
      tag.span(safe_join([(@icon ? helpers.ui_icon(@icon) : nil), @label].compact), class: [css_classes, extra_class].compact.join(" "), **@options)
    end

    private

    def css_classes
      if @style == :pill
        [PILL_BASE, @active ? PILL_ACTIVE : PILL_INACTIVE].join(" ")
      else
        [BADGE_BASE, STATUS.fetch(@variant)].join(" ")
      end
    end
  end
end
