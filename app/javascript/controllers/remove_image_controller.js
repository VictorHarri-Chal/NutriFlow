import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hidden", "preview", "hint"]
  static values  = { removedText: String }

  remove() {
    if (this.hasHiddenTarget)  this.hiddenTarget.value = "1"
    if (this.hasPreviewTarget) this.previewTarget.style.display = "none"
    if (this.hasHintTarget && this.removedTextValue) {
      this.hintTarget.textContent = this.removedTextValue
    }
  }
}
