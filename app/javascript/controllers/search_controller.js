import { Controller } from "@hotwired/stimulus"

// Debounced auto-submit for search forms.
// Attach to the <form> element; add data-action="input->search#input" on inputs.
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  connect()    { this._timer = null }
  disconnect() { clearTimeout(this._timer) }

  input() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }
}
