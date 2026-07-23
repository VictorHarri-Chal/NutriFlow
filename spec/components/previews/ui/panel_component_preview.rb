module Ui
  class PanelComponentPreview < ViewComponent::Preview
    def default
      render(Ui::PanelComponent.new) { "Contenu du panneau." }
    end
  end
end
