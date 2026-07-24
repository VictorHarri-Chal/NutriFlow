module ApplicationHelper
  include Pagy::Frontend

  # Formate une valeur nutritionnelle : supprime les zéros décimaux inutiles
  # Ex : 359.0 → "359", 13.5 → "13.5"
  def format_macro(value)
    number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
  end

  # Traduit un statut d'anneau (Profile#ring_status) en classe de couleur de
  # texte, pour homogénéiser le code couleur des macros/calories hors des anneaux
  # (ex. le total calorique du header). Retombe sur une couleur neutre si nil.
  RING_STATUS_TEXT_CLASS = {
    success: "text-status-success",
    warning: "text-status-warning",
    danger:  "text-status-danger"
  }.freeze

  def ring_status_text_class(status)
    RING_STATUS_TEXT_CLASS.fetch(status, "text-ink-primary")
  end

  def nested_dom_id(*args)
    args.map { |arg| arg.respond_to?(:to_key) ? dom_id(arg) : arg }.join("_")
  end

  def weight_sidebar_label_key(user)
    if user.show_weight_tracking? && user.show_body_measurements?
      "weight_and_measurements"
    elsif user.show_body_measurements?
      "measurements"
    else
      "weight"
    end
  end

  def delete_link_with_confirm(path, options = {})
    message = options.delete(:confirm) || I18n.t("shared.delete_confirm")
    icon_class = options.delete(:icon_class) || "fa fa-trash"
    title = options.delete(:title) || I18n.t("shared.delete")
    link_class = options.delete(:class) || "inline-block text-status-danger hover:text-red-400 transition-colors"
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

  # Helper pour créer des liens de déconnexion avec confirmation personnalisée
  def logout_link_with_confirm(path, options = {})
    message = options.delete(:confirm) || I18n.t("views.shared.sidebar.logout_confirm")
    icon_class = options.delete(:icon_class) || "fas fa-sign-out-alt w-5 h-5 mr-3"
    text = options.delete(:text) || I18n.t("views.shared.sidebar.logout")
    link_class = options.delete(:class) || "flex items-center px-4 py-3 text-ink-muted hover:bg-status-danger_dim/20 hover:text-status-danger rounded-lg transition-colors"

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
