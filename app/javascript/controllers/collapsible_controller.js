import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "trigger", "icon"]

  connect() {
    this.contentTarget.classList.add("hidden")
  }

  toggle() {
    this.contentTarget.classList.toggle("hidden")
    this.iconTarget.classList.toggle("rotate-180")
  }

  show() {
    this.contentTarget.classList.remove("hidden")
    this.iconTarget.classList.add("rotate-180")
  }

  hide() {
    this.contentTarget.classList.add("hidden")
    this.iconTarget.classList.remove("rotate-180")
  }
}
