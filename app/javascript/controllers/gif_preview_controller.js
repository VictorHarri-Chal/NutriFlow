import { Controller } from "@hotwired/stimulus"

// On connect: draws the first frame of the GIF onto a <canvas> (frozen thumbnail).
// On mouseenter: replaces the canvas with the live animated GIF.
// On mouseleave: clears the GIF src (stops animation) and restores the canvas.
export default class extends Controller {
  static targets = ["placeholder", "canvas", "gif"]
  static values  = { src: String }

  connect() {
    if (!this.hasSrcValue || !this.srcValue) return

    const img = new Image()
    img.onload = () => {
      const canvas = this.canvasTarget
      canvas.width  = img.naturalWidth
      canvas.height = img.naturalHeight
      canvas.getContext("2d").drawImage(img, 0, 0)
      // Show the frozen first frame, hide the generic placeholder
      this.placeholderTarget.classList.add("hidden")
      canvas.classList.remove("hidden")
    }
    // img.onerror: placeholder stays visible — no action needed
    img.src = this.srcValue
  }

  mouseenter() {
    if (!this.hasSrcValue || !this.srcValue) return
    this.gifTarget.src = this.srcValue
    this.gifTarget.classList.remove("hidden")
    this.canvasTarget.classList.add("hidden")
  }

  mouseleave() {
    this.gifTarget.src = ""                        // stops the animation
    this.gifTarget.classList.add("hidden")
    this.canvasTarget.classList.remove("hidden")   // restore frozen frame
  }
}
