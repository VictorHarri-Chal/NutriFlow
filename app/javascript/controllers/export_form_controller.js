import { Controller } from "@hotwired/stimulus"

// Export tab form (Réglages) — two independent concerns on one controller:
// - showing/disabling the custom date inputs based on the period radio
// - disabling the submit button until at least one category is checked
export default class extends Controller {
  static targets = ["periodRadio", "customDates", "categoryCheckbox", "submitButton"]

  connect() {
    this._refreshCustomDates()
    this._refreshSubmitButton()
  }

  periodChanged() {
    this._refreshCustomDates()
  }

  categoryChanged() {
    this._refreshSubmitButton()
  }

  _refreshCustomDates() {
    const isCustom = this.periodRadioTargets.find(r => r.checked)?.value === "custom"
    this.customDatesTarget.classList.toggle("hidden", !isCustom)
    this.customDatesTarget.querySelectorAll("input").forEach(input => {
      input.disabled = !isCustom
    })
  }

  _refreshSubmitButton() {
    const anyChecked = this.categoryCheckboxTargets.some(cb => cb.checked)
    this.submitButtonTarget.disabled = !anyChecked
    this.submitButtonTarget.classList.toggle("opacity-40", !anyChecked)
    this.submitButtonTarget.classList.toggle("cursor-not-allowed", !anyChecked)
  }
}
