import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "trigger", "icon"]

  connect() {
    const saved = this.storageKey ? localStorage.getItem(this.storageKey) : null
    const openByDefault = this.element.hasAttribute("data-collapsible-open-by-default")
    const forceOpen = this.element.hasAttribute("data-collapsible-force-open")
    if (forceOpen || saved === "open" || (saved === null && openByDefault)) {
      this._open(true)
    } else {
      this._close(false)
    }

    if (this.group) {
      this._boundGroupClose = this._onGroupOpen.bind(this)
      document.addEventListener("collapsible:open", this._boundGroupClose)
    }

    this._boundOpenRequest = this._onOpenRequest.bind(this)
    document.addEventListener("collapsible:open-request", this._boundOpenRequest)
  }

  disconnect() {
    clearTimeout(this._outsideClickTimer)
    this._removeOutsideClick()
    if (this._boundGroupClose) {
      document.removeEventListener("collapsible:open", this._boundGroupClose)
    }
    document.removeEventListener("collapsible:open-request", this._boundOpenRequest)
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
      this._outsideClickTimer = setTimeout(() => document.addEventListener("click", this._boundOutsideClick), 0)
    }
    if (this.group) {
      document.dispatchEvent(new CustomEvent("collapsible:open", { detail: { group: this.group, source: this.element } }))
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

  _onGroupOpen(event) {
    if (event.detail.group === this.group && event.detail.source !== this.element) {
      this._close(false)
    }
  }

  // Lets an element elsewhere on the page (e.g. a persistent status banner
  // linking to this section) request that this specific instance open itself,
  // identified by DOM id — see expand_link_controller.js.
  _onOpenRequest(event) {
    if (event.detail.id && event.detail.id === this.element.id) {
      this._open(true)
    }
  }

  get storageKey() {
    return this.element.dataset.collapsibleStorageKey || null
  }

  get group() {
    return this.element.dataset.collapsibleGroup || null
  }
}
