import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 800 } }

  connect() {
    this._timeout = null
  }

  save() {
    clearTimeout(this._timeout)
    this._timeout = setTimeout(() => {
      const form = this.element.closest("form")
      if (form) form.requestSubmit()
    }, this.delayValue)
  }

  disconnect() {
    clearTimeout(this._timeout)
  }
}
