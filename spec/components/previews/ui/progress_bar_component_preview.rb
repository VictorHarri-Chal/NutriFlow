module Ui
  class ProgressBarComponentPreview < ViewComponent::Preview
    def default
      render Ui::ProgressBarComponent.new(percent: 30)
    end

    def three_quarters
      render Ui::ProgressBarComponent.new(percent: 75)
    end

    # Value above 100 is clamped to 100.
    def over_100_clamped
      render Ui::ProgressBarComponent.new(percent: 150)
    end
  end
end
