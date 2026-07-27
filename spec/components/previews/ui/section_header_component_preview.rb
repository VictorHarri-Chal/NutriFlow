module Ui
  class SectionHeaderComponentPreview < ViewComponent::Preview
    # @param size select { choices: [base, sm] }
    def with_description(size: :base)
      render Ui::SectionHeaderComponent.new(icon: "fa-sliders", title: "Général",
                                            description: "Gérez vos préférences.", size: size.to_sym)
    end

    def with_actions
      render Ui::SectionHeaderComponent.new(icon: "fa-chart-line", title: "Évolution", size: :sm) do |c|
        c.with_actions do
          tag.span("30 jours", class: "px-3 py-1 rounded-full text-xs font-medium border bg-brand/20 text-brand border-brand/50")
        end
      end
    end
  end
end
