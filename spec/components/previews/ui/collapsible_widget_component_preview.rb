module Ui
  # Note: the open/closed persistence (localStorage) and rotate animation on the
  # chevron are driven by the `collapsible` Stimulus controller — only the
  # initial state (forced open, or open-by-default via CSS) is visible here.
  class CollapsibleWidgetComponentPreview < ViewComponent::Preview
    def default
      render Ui::CollapsibleWidgetComponent.new(title: "Repas", storage_key: "meals") do |c|
        c.with_content_body { "Poulet curry, riz basmati, brocolis vapeur." }
      end
    end
  end
end
