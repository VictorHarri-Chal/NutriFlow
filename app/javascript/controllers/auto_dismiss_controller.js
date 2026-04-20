import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._timeout = setTimeout(() => this._dismiss(), 3000)
  }

  disconnect() {
    clearTimeout(this._timeout)
  }

  _dismiss() {
    this.element.style.transition = "opacity 0.4s ease-out, transform 0.4s ease-out"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateX(1rem)"
    setTimeout(() => this.element.remove(), 400)
  }
}
