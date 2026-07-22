import { Controller } from "@hotwired/stimulus"

// Program day column: the tiny duration input stays user-controlled. When its
// value differs from the server-computed estimate (estimateValue, 0 when the
// day has no exercises), a small warning icon appears. Clicking the icon
// applies the estimate and persists it via the field's existing auto-submit.
export default class extends Controller {
  static targets = ["input", "icon"]
  static values  = { estimate: Number }

  connect() { this._sync() }
  sync()    { this._sync() }

  apply() {
    if (this.estimateValue <= 0) return
    this.inputTarget.value = this.estimateValue
    this._sync()
    this.inputTarget.dispatchEvent(new Event("blur")) // reuse auto-submit to persist
  }

  _sync() {
    if (!this.hasIconTarget) return
    const current = parseInt(this.inputTarget.value, 10) || 0
    const differs = this.estimateValue > 0 && this.estimateValue !== current
    this.iconTarget.classList.toggle("hidden", !differs)
  }
}
