import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template"]

  connect() {
    this._boundRemoveModal = this.removeModal.bind(this)
    document.addEventListener("turbo:before-cache", this._boundRemoveModal)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this._boundRemoveModal)
    this.removeModal()
  }

  open({ params: { photoUrl, date, measurements } }) {
    if (!photoUrl) return

    this.removeModal()

    const modal = this.templateTarget.content.cloneNode(true)
    modal.querySelector('[data-slot="date"]').textContent = date || ""
    modal.querySelector('[data-slot="image"]').src = photoUrl
    modal.querySelector('[data-slot="measurements"]').textContent = measurements || ""

    document.body.appendChild(modal)
  }

  removeModal() {
    document.querySelectorAll("[data-measurement-photo-modal]").forEach(el => el.remove())
  }
}
