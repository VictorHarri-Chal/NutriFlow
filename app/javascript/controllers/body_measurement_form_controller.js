import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dateField", "field"]
  static values  = { entries: Object }

  connect() {
    this.checkDate()
  }

  checkDate() {
    const selected = this.dateFieldTarget.value
    const existing = this.entriesValue[selected] || {}

    this.fieldTargets.forEach(input => {
      input.value = existing[input.dataset.field] ?? ""
    })
  }
}
