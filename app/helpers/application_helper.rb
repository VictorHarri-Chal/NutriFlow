module ApplicationHelper
  include Pagy::Frontend

  def nested_dom_id(*args)
    args.map { |arg| arg.respond_to?(:to_key) ? dom_id(arg) : arg }.join("_")
  end

  def delete_link_with_confirm(path, options = {})
    message = options.delete(:confirm) || "Es-tu sûr de vouloir supprimer cet élément ?"
    icon_class = options.delete(:icon_class) || "fa fa-trash"
    title = options.delete(:title) || "Supprimer"
    link_class = options.delete(:class) || "inline-block text-red-600 hover:text-red-900"
    text = options.delete(:text)

    link_to path,
            data: {
              turbo_method: :delete,
              action: "click->confirm#show",
              confirm_message: message
            },
            class: link_class,
            title: title do
      if text.present?
        content_tag :span, text
      else
        content_tag :i, nil, class: icon_class
      end
    end
  end

    # Helper pour créer des boutons de suppression avec confirmation personnalisée
  def delete_button_with_confirm(path, options = {})
    message = options.delete(:confirm) || "Es-tu sûr de vouloir supprimer cet élément ?"
    text = options.delete(:text) || "Supprimer"
    button_class = options.delete(:class) || "btn btn-danger"

    button_to path,
              method: :delete,
              data: {
                action: "click->confirm#show",
                confirm_message: message
              },
              class: button_class do
      text
    end
  end

  # Helper pour créer des liens de déconnexion avec confirmation personnalisée
  def logout_link_with_confirm(path, options = {})
    message = options.delete(:confirm) || "Es-tu sûr de vouloir te déconnecter ?"
    icon_class = options.delete(:icon_class) || "fas fa-sign-out-alt w-5 h-5 mr-3"
    text = options.delete(:text) || "Déconnexion"
    link_class = options.delete(:class) || "flex items-center px-4 py-3 text-gray-700 hover:bg-red-50 hover:text-red-600 rounded-lg"

    link_to path,
            data: {
              turbo_method: :delete,
              action: "click->confirm#show",
              confirm_message: message
            },
            class: link_class do
      content_tag(:i, nil, class: icon_class) + content_tag(:span, text, class: "font-medium pb-1")
    end
  end
end
