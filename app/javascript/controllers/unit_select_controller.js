import { Controller } from "@hotwired/stimulus"

// Custom unit select dropdown for form fields.
// Stores the chosen value in a hidden input.
export default class extends Controller {
  static targets = ["trigger", "label", "icon", "dropdown", "hiddenInput"]

  static values = { default: { type: String, default: "g" } }

  connect() {
    this._boundClose = this._onOutsideClick.bind(this)
    const initial = this.hiddenInputTarget.value || this.defaultValue
    if (initial) {
      this.hiddenInputTarget.value = initial
      this.labelTarget.textContent = initial
      this.labelTarget.classList.remove("text-ink-subtle")
    }
  }

  disconnect() {
    document.removeEventListener("click", this._boundClose)
  }

  toggle(event) {
    event.stopPropagation()
    this.dropdownTarget.classList.contains("hidden") ? this._open() : this._close()
  }

  select(event) {
    const value = event.currentTarget.dataset.value
    this.hiddenInputTarget.value = value
    this.labelTarget.textContent = value || "—"
    this._close()
    this.hiddenInputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  _open() {
    this.dropdownTarget.classList.remove("hidden")
    this.iconTarget.classList.add("rotate-180")
    document.addEventListener("click", this._boundClose)
  }

  _close() {
    this.dropdownTarget.classList.add("hidden")
    this.iconTarget.classList.remove("rotate-180")
    document.removeEventListener("click", this._boundClose)
  }

  _onOutsideClick(event) {
    if (!this.element.contains(event.target)) this._close()
  }
}
