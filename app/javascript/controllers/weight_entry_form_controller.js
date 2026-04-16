import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dateField", "weightField", "hint"]
  static values  = { entries: Array }

  connect() {
    this.checkDate()
  }

  checkDate() {
    const selected = this.dateFieldTarget.value
    const existing = this.entriesValue.find(e => e.date === selected)

    if (existing) {
      this.weightFieldTarget.value = existing.weight
      if (this.hasHintTarget) {
        this.hintTarget.textContent = this.hintTarget.dataset.existingMessage
          .replace("%{weight}", existing.weight)
        this.hintTarget.classList.remove("hidden")
      }
    } else {
      this.weightFieldTarget.value = ""
      if (this.hasHintTarget) {
        this.hintTarget.classList.add("hidden")
      }
    }
  }
}
