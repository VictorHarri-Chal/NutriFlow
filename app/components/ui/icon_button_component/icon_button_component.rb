module Ui
  # Compact icon-only action button (edit / delete / duplicate…).
  # Renders a link_to when `href:` is given, otherwise a plain <button>.
  #
  #   Ui::IconButtonComponent.new(icon: :delete, variant: :delete, href: path,
  #                               confirm: "…", title: "…", size: :md)
  class IconButtonComponent < ApplicationComponent
    BASE = "inline-flex items-center justify-center transition-colors".freeze
    SIZES = {
      md:   "w-8 h-8 rounded-lg",
      sm:   "w-7 h-7 rounded-lg",
      card: "p-1.5 rounded"
    }.freeze
    ICON_SIZES = { md: "text-sm", sm: "text-xs", card: "text-[11px]" }.freeze
    VARIANTS = {
      neutral: "hover:text-ink-primary hover:bg-surface-hover",
      brand:   "hover:text-brand hover:bg-surface-hover",
      edit:    "hover:text-brand hover:bg-surface-hover",
      danger:  "hover:text-status-danger hover:bg-status-danger/10",
      delete:  "hover:text-status-danger hover:bg-status-danger/10"
    }.freeze

    def initialize(icon:, variant: :neutral, size: :md, href: nil, method: nil, title: nil, confirm: nil, aria_label: nil, **options)
      @icon = icon; @variant = variant; @size = size
      @href = href; @method = method; @title = title; @confirm = confirm
      @aria_label = aria_label; @options = options
    end

    def call
      extra_class = @options.delete(:class)
      extra_data  = @options.delete(:data) || {}
      extra_aria  = @options.delete(:aria) || {}
      merged_class = [css_classes, extra_class].compact.join(" ")
      merged_data  = action_data.merge(extra_data)
      merged_aria  = aria_hash.merge(extra_aria)

      attrs = {
        class: merged_class,
        title: @title,
        aria: merged_aria.presence,
        data: merged_data.presence
      }.compact.merge(@options)

      if @href
        link_to(@href, **attrs) { icon_tag }
      else
        tag.button(icon_tag, type: "button", **attrs)
      end
    end

    private

    def css_classes
      [BASE, SIZES.fetch(@size), base_color, VARIANTS.fetch(@variant)].join(" ")
    end

    def base_color
      @size == :card ? "text-ink-subtle/50" : "text-ink-subtle"
    end

    def icon_tag
      if @icon.is_a?(Symbol)
        helpers.ui_icon(@icon, css: ICON_SIZES.fetch(@size))
      else
        tag.i(class: "fas #{@icon} #{ICON_SIZES.fetch(@size)}")
      end
    end

    def action_data
      if @confirm
        { turbo_method: @method || :delete, action: "click->confirm#show", confirm_message: @confirm }
      elsif @method
        { turbo_method: @method }
      else
        {}
      end
    end

    def aria_hash
      @aria_label ? { label: @aria_label } : {}
    end
  end
end
