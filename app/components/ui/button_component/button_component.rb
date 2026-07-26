module Ui
  class ButtonComponent < ApplicationComponent
    VARIANTS = { primary: "btn-primary", secondary: "btn-secondary", danger: "btn-danger", ghost: "btn-ghost" }.freeze
    SIZES = { sm: "text-xs px-3 py-1.5", md: "", lg: "text-base px-6 py-3" }.freeze

    def initialize(label: nil, variant: :primary, size: :md, icon: nil, href: nil, method: nil, aria_label: nil, type: "button", **options)
      @label = label; @variant = variant; @size = size; @icon = icon
      @href = href; @method = method; @aria_label = aria_label; @type = type; @options = options
    end

    def call
      extra_class = @options.delete(:class)
      extra_data = @options.delete(:data) || {}
      extra_aria = @options.delete(:aria) || {}
      merged_class = [css_classes, extra_class].compact.join(" ")
      merged_data = link_data.merge(extra_data)
      merged_aria = aria_hash.merge(extra_aria)

      inner = safe_join([icon_tag, label_tag].compact)
      if @href
        link_to(@href, class: merged_class, aria: merged_aria, data: merged_data, **@options) { inner }
      else
        tag.button(inner, type: @type, class: merged_class, aria: merged_aria, data: merged_data, **@options)
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
