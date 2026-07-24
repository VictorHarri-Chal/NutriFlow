module Ui
  # Note: the open/close scale + fade animation is driven by the `modal` Stimulus
  # controller's connect()/close() lifecycle, so it is only visible when the
  # component is actually mounted in the app (e.g. via a Turbo Stream update),
  # not inside this static Lookbook preview frame.
  class ModalComponentPreview < ViewComponent::Preview
    # @param max_width select { choices: [sm, md, lg, xl] }
    def default(max_width: :md)
      render Ui::ModalComponent.new(title: "Historique", max_width: max_width.to_sym) do |m|
        m.with_body { "Corps de la fenêtre." }
      end
    end

    def with_footer
      render Ui::ModalComponent.new(title: "Confirmer la suppression") do |m|
        m.with_body { "Cette action est irréversible." }
        m.with_footer { "Annuler / Confirmer" }
      end
    end

    def with_icon
      render Ui::ModalComponent.new(title: "Avertissement", icon: "fa-triangle-exclamation") do |m|
        m.with_body { "Un point de vigilance avant de continuer." }
      end
    end
  end
end
