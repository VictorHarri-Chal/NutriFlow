import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "trigger", "icon"]

  connect() {
    const saved = this.storageKey ? localStorage.getItem(this.storageKey) : null
    const openByDefault = this.element.hasAttribute("data-collapsible-open-by-default")
    if (saved === "open" || (saved === null && openByDefault)) {
      this._open(false)
    } else {
      this._close(false)
    }
  }

  disconnect() {
    this._removeOutsideClick()
  }

  toggle() {
    if (this.contentTarget.classList.contains("hidden")) {
      this._open(true)
    } else {
      this._close(true)
    }
  }

  // Stops propagation so clicks inside the content area don't bubble to a parent toggle
  stopEvent(event) {
    event.stopPropagation()
  }

  // Kept for backward compatibility
  show() { this._open(true) }
  hide() { this._close(true) }

  _open(persist) {
    this.contentTarget.classList.remove("hidden")
    if (this.hasIconTarget) this.iconTarget.classList.add("rotate-180")
    if (persist && this.storageKey) localStorage.setItem(this.storageKey, "open")
    if (this.element.hasAttribute("data-collapsible-dismiss-on-outside-click")) {
      this._boundOutsideClick = this._onOutsideClick.bind(this)
      setTimeout(() => document.addEventListener("click", this._boundOutsideClick), 0)
    }
  }

  _close(persist) {
    this.contentTarget.classList.add("hidden")
    if (this.hasIconTarget) this.iconTarget.classList.remove("rotate-180")
    if (persist && this.storageKey) localStorage.setItem(this.storageKey, "closed")
    this._removeOutsideClick()
  }

  _onOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this._close(true)
    }
  }

  _removeOutsideClick() {
    if (this._boundOutsideClick) {
      document.removeEventListener("click", this._boundOutsideClick)
      this._boundOutsideClick = null
    }
  }

  get storageKey() {
    return this.element.dataset.collapsibleStorageKey || null
  }
}
