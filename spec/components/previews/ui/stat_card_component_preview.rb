module Ui
  class StatCardComponentPreview < ViewComponent::Preview
    def default
      render Ui::StatCardComponent.new(label: "Calories", value: "1 850", unit: "kcal")
    end

    def colored_value
      render Ui::StatCardComponent.new(label: "Protéines", value: "142", unit: "g", value_color: "text-macro-proteins")
    end
  end
end
