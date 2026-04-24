import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this._boundClose  = this._onOutsideClick.bind(this)
    this._listenerActive = false
  }

  disconnect() {
    this._removeListener()
  }

  open(event) {
    event.preventDefault()
    this.panelTarget.classList.remove("opacity-0", "scale-95", "pointer-events-none")
    this.panelTarget.classList.add("opacity-100", "scale-100", "pointer-events-auto")
    // Defer so the current click event doesn't immediately trigger _onOutsideClick
    requestAnimationFrame(() => this._addListener())
  }

  close() {
    this.panelTarget.classList.remove("opacity-100", "scale-100", "pointer-events-auto")
    this.panelTarget.classList.add("opacity-0", "scale-95", "pointer-events-none")
    this._removeListener()
  }

  _onOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  _addListener() {
    if (this._listenerActive) return
    document.addEventListener("click", this._boundClose)
    this._listenerActive = true
  }

  _removeListener() {
    if (!this._listenerActive) return
    document.removeEventListener("click", this._boundClose)
    this._listenerActive = false
  }
}
