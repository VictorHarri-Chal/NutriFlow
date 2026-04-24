import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this._boundClose = this._onOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this._boundClose)
  }

  open(event) {
    event.preventDefault()
    this.panelTarget.classList.remove("opacity-0", "scale-95", "pointer-events-none")
    this.panelTarget.classList.add("opacity-100", "scale-100", "pointer-events-auto")
    requestAnimationFrame(() => {
      document.addEventListener("click", this._boundClose)
    })
  }

  close() {
    this.panelTarget.classList.remove("opacity-100", "scale-100", "pointer-events-auto")
    this.panelTarget.classList.add("opacity-0", "scale-95", "pointer-events-none")
    document.removeEventListener("click", this._boundClose)
  }

  _onOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
