module Ui
  class EmptyStateComponentPreview < ViewComponent::Preview
    # @param size select { choices: [lg, md, sm] }
    def with_cta(size: :lg)
      render Ui::EmptyStateComponent.new(icon: "fa-utensils", title: "Aucun repas enregistré",
                                         hint: "Commencez par ajouter un aliment à votre journée.", size: size.to_sym) do |c|
        c.with_cta { render Ui::ButtonComponent.new(label: "Ajouter", icon: :add, variant: :secondary, size: :sm) }
      end
    end

    def without_cta
      render Ui::EmptyStateComponent.new(icon: "fa-chart-line", title: "Pas encore de données")
    end
  end
end
