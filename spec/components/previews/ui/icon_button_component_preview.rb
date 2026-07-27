module Ui
  class IconButtonComponentPreview < ViewComponent::Preview
    # @param variant select { choices: [neutral, brand, edit, danger, delete] }
    # @param size select { choices: [md, sm, card] }
    def playground(variant: :neutral, size: :md)
      render Ui::IconButtonComponent.new(icon: :edit, variant: variant.to_sym, size: size.to_sym, title: "Modifier", href: "#")
    end

    def delete_with_confirm
      render Ui::IconButtonComponent.new(icon: :delete, variant: :delete, href: "#",
                                         confirm: "Supprimer cet élément ?", title: "Supprimer")
    end

    def raw_glyph
      render Ui::IconButtonComponent.new(icon: "fa-copy", variant: :neutral, href: "#", title: "Dupliquer")
    end

    def session_card_dialect
      render Ui::IconButtonComponent.new(icon: :edit, variant: :neutral, size: :card, href: "#", title: "Modifier")
    end
  end
end
