module Ui
  class ButtonComponent < ApplicationComponent
    VARIANTS = { primary: "btn-primary", secondary: "btn-secondary", danger: "btn-danger", ghost: "btn-ghost" }.freeze
    SIZES = { sm: "text-xs px-3 py-1.5", md: "", lg: "text-base px-6 py-3" }.freeze

    def initialize(label: nil, variant: :primary, size: :md, icon: nil, href: nil, method: nil, aria_label: nil, type: "button", **options)
      @label = label; @variant = variant; @size = size; @icon = icon
      @href = href; @method = method; @aria_label = aria_label; @type = type; @options = options
    end

    def call
      inner = safe_join([icon_tag, label_tag].compact)
      if @href
        link_to(@href, class: css_classes, aria: aria_hash, data: link_data, **@options) { inner }
      else
        tag.button(inner, type: @type, class: css_classes, aria: aria_hash, **@options)
      end
    end

    private

    def css_classes
      [VARIANTS.fetch(@variant), SIZES.fetch(@size)].reject(&:blank?).join(" ")
    end

    def icon_tag
      @icon ? helpers.ui_icon(@icon) : nil
    end

    def label_tag
      @label.blank? ? nil : tag.span(@label)
    end

    def aria_hash
      @aria_label ? { label: @aria_label } : {}
    end

    def link_data
      @method ? { turbo_method: @method } : {}
    end
  end
end
