module Ui
  class FieldComponentPreview < ViewComponent::Preview
    def default
      render Ui::FieldComponent.new(
        name: "recipe_name",
        label: "Nom de la recette",
        value: "Poulet curry",
        hint: "80 caractères max.",
        maxlength: 80
      )
    end

    def with_errors
      render Ui::FieldComponent.new(
        name: "recipe_name",
        label: "Nom de la recette",
        value: "",
        errors: ["ne peut pas être vide"]
      )
    end
  end
end
