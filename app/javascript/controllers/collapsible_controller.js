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

  toggle() {
    if (this.contentTarget.classList.contains("hidden")) {
      this._open(true)
    } else {
      this._close(true)
    }
  }

  // Kept for backward compatibility
  show() { this._open(true) }
  hide() { this._close(true) }

  _open(persist) {
    this.contentTarget.classList.remove("hidden")
    this.iconTarget.classList.add("rotate-180")
    if (persist && this.storageKey) localStorage.setItem(this.storageKey, "open")
  }

  _close(persist) {
    this.contentTarget.classList.add("hidden")
    this.iconTarget.classList.remove("rotate-180")
    if (persist && this.storageKey) localStorage.setItem(this.storageKey, "closed")
  }

  get storageKey() {
    return this.element.dataset.collapsibleStorageKey || null
  }
}
