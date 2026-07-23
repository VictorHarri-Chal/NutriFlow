module Ui
  class ButtonComponentPreview < ViewComponent::Preview
    # @param variant select { choices: [primary, secondary, danger, ghost] }
    # @param size select { choices: [sm, md, lg] }
    def playground(variant: :primary, size: :md)
      render Ui::ButtonComponent.new(label: "Enregistrer", variant: variant.to_sym, size: size.to_sym, icon: :check)
    end

    def icon_only
      render Ui::ButtonComponent.new(icon: :edit, aria_label: "Modifier", variant: :ghost)
    end

    def as_link
      render Ui::ButtonComponent.new(label: "Voir les aliments", href: "/foods", icon: :add, variant: :secondary)
    end
  end
end
