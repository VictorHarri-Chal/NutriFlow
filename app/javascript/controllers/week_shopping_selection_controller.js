import { Controller } from "@hotwired/stimulus"

// Selection counter for the "week generation" modal's checkbox list —
// stacked on the same element as the generic `modal` controller.
export default class extends Controller {
  static targets = ["checkbox", "counter", "submitButton"]
  static values  = { selectedTemplate: String }

  connect() {
    this._updateCounter()
  }

  toggle() {
    this._updateCounter()
  }

  _updateCounter() {
    if (!this.hasCheckboxTarget) return

    const total    = this.checkboxTargets.length
    const selected = this.checkboxTargets.filter(cb => cb.checked).length

    if (this.hasCounterTarget && this.hasSelectedTemplateValue) {
      this.counterTarget.textContent = this.selectedTemplateValue
        .replace("__SELECTED__", selected)
        .replace("__TOTAL__", total)
    }

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = selected === 0
      this.submitButtonTarget.classList.toggle("opacity-40", selected === 0)
      this.submitButtonTarget.classList.toggle("cursor-not-allowed", selected === 0)
    }
  }
}
