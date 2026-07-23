module Ui
  # Note: the visible dropdown list is built entirely client-side by the
  # `custom-select` Stimulus controller from the hidden select's <option>s
  # (see buildDropdown() in custom_select_controller.js) — the server only
  # renders the hidden <select> and an empty dropdown container.
  class CustomSelectComponentPreview < ViewComponent::Preview
    def default
      render Ui::CustomSelectComponent.new(
        name: "period",
        choices: [["7 jours", "7"], ["30 jours", "30"]],
        selected: "7"
      )
    end
  end
end
