import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pill", "tab"]

  select(event) {
    event.preventDefault()
    const link = event.currentTarget
    const index = this.tabTargets.indexOf(link)

    if (index === 0) {
      this.pillTarget.style.left = "4px"
      this.pillTarget.style.right = "50%"
    } else {
      this.pillTarget.style.left = "50%"
      this.pillTarget.style.right = "4px"
    }

    setTimeout(() => { Turbo.visit(link.href) }, 220)
  }
}
