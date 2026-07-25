module Ui
  class ChartPlaceholderComponentPreview < ViewComponent::Preview
    def default
      render Ui::ChartPlaceholderComponent.new(icon: "fa-chart-line", text: "Pas assez de données", height: "h-40")
    end

    def with_subtext
      render Ui::ChartPlaceholderComponent.new(icon: "fa-trophy", text: "Aucun record pour l'instant",
                                               subtext: "Les PRs sont détectés automatiquement à chaque nouvelle performance.", height: "py-10")
    end
  end
end
