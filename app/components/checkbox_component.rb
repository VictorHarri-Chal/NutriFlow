# frozen_string_literal: true

# Dark-theme checkbox used everywhere a real (visible) checkbox is needed —
# e.g. the export category list, the shopping-list week-generation modal.
# Pure CSS via the `peer` pattern: a visually-hidden real <input> keeps full
# keyboard accessibility and native form submission, while the sibling box
# renders the amber-on-dark checked state. Not for on/off switches (use
# PreferenceToggleComponent) or hidden pill-backing checkboxes (set types,
# food labels), which are deliberately styled differently.
class CheckboxComponent < ApplicationComponent
  def initialize(name:, value: nil, checked: false, **attributes)
    @name = name
    @value = value
    @checked = checked
    @attributes = attributes
  end
end
