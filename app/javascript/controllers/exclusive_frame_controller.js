import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  clear(event) {
    const targetId = event.currentTarget.dataset.turboFrame
    this.element.querySelectorAll("[data-turbo-frame]").forEach(link => {
      if (link.dataset.turboFrame !== targetId) {
        const frame = document.getElementById(link.dataset.turboFrame)
        if (frame) frame.innerHTML = ""
      }
    })
  }
}
