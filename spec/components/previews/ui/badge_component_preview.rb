module Ui
  class BadgeComponentPreview < ViewComponent::Preview
    # @param variant select { choices: [brand, success, warning, danger, info, neutral] }
    # @param size select { choices: [md, sm] }
    def status(variant: :success, size: :md)
      render Ui::BadgeComponent.new("Statut", variant: variant.to_sym, size: size.to_sym)
    end

    # @param active toggle
    def filter_pill(active: true)
      render Ui::BadgeComponent.new("Favoris", style: :pill, active: active)
    end
  end
end
