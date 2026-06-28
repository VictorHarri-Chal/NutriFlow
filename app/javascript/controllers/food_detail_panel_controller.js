import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "panel"]

  connect() {
    this._onFrameLoad = this._handleFrameLoad.bind(this)
    this._onKeydown   = this._handleKeydown.bind(this)
    document.addEventListener("turbo:frame-load", this._onFrameLoad)
    document.addEventListener("keydown", this._onKeydown)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this._onFrameLoad)
    document.removeEventListener("keydown", this._onKeydown)
  }

  open() {
    this.overlayTarget.classList.remove("opacity-0", "pointer-events-none")
    this.overlayTarget.classList.add("opacity-100")
    this.panelTarget.classList.remove("translate-x-full")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.overlayTarget.classList.remove("opacity-100")
    this.overlayTarget.classList.add("opacity-0")
    this.panelTarget.classList.add("translate-x-full")
    document.body.style.overflow = ""
    setTimeout(() => {
      this.overlayTarget.classList.add("pointer-events-none")
      const frame = document.getElementById("food_detail")
      if (frame) frame.innerHTML = ""
    }, 300)
  }

  _handleFrameLoad(event) {
    if (event.target.id === "food_detail") this.open()
  }

  _handleKeydown(event) {
    if (event.key === "Escape") this.close()
  }
}
