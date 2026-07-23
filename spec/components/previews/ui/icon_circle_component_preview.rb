module Ui
  class IconCircleComponentPreview < ViewComponent::Preview
    # @param size select { choices: [sm, md, lg] }
    def default(size: :md)
      render Ui::IconCircleComponent.new(icon: "fa-user", size: size.to_sym)
    end

    def small
      render Ui::IconCircleComponent.new(icon: "fa-utensils", size: :sm)
    end

    def large
      render Ui::IconCircleComponent.new(icon: "fa-dumbbell", size: :lg)
    end
  end
end
