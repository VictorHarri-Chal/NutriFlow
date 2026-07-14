import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "icon"]

  connect() {
    this.update()
  }

  update() {
    const file = this.inputTarget.files[0]

    this.iconTarget.classList.toggle("fa-xmark", !file)
    this.iconTarget.classList.toggle("text-ink-subtle", !file)
    this.iconTarget.classList.toggle("fa-check", !!file)
    this.iconTarget.classList.toggle("text-status-success", !!file)
    this.iconTarget.dataset.tooltip = file ? file.name : ""
  }
}
