import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "sheet"]

  open() {
    this.overlayTarget.classList.remove("opacity-0", "pointer-events-none")
    this.overlayTarget.classList.add("opacity-100")
    this.sheetTarget.classList.remove("translate-y-full")
    document.body.style.overflow = "hidden"
  }

  disconnect() {
    clearTimeout(this._closeTimer)
    document.body.style.overflow = ""
  }

  close() {
    this.overlayTarget.classList.add("opacity-0")
    this.overlayTarget.classList.remove("opacity-100")
    this.sheetTarget.classList.add("translate-y-full")
    clearTimeout(this._closeTimer)
    this._closeTimer = setTimeout(() => {
      this.overlayTarget.classList.add("pointer-events-none")
      document.body.style.overflow = ""
    }, 300)
  }

  // Close on Escape key
  keydown(event) {
    if (event.key === "Escape") this.close()
  }
}
