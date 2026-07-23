module Ui
  class StatCardComponent < ApplicationComponent
    def initialize(label:, value:, unit: nil, value_color: "text-ink-primary")
      @label = label; @value = value; @unit = unit; @value_color = value_color
    end

    def call
      render(Ui::PanelComponent.new(padding: "px-5 py-5")) do
        safe_join([
          tag.p(@label, class: "text-xs font-medium text-ink-subtle uppercase tracking-wider mb-2"),
          tag.p(safe_join([@value, unit_tag].compact), class: "text-2xl font-bold #{@value_color}")
        ])
      end
    end

    private

    def unit_tag
      @unit ? tag.span(" #{@unit}", class: "text-xs font-normal text-ink-subtle") : nil
    end
  end
end
