import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "input", "form"]

  edit(event) {
    event.stopPropagation()
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  keydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this._submit()
    } else if (event.key === "Escape") {
      this.cancel()
    }
  }

  blur() {
    // Delay allows requestSubmit() to fire before blur hides the form
    setTimeout(() => {
      if (this.hasFormTarget && !this.formTarget.classList.contains("hidden")) {
        this._submit()
      }
    }, 200)
  }

  cancel() {
    this.displayTarget.classList.remove("hidden")
    this.formTarget.classList.add("hidden")
  }

  _submit() {
    this.formTarget.requestSubmit()
  }
}
