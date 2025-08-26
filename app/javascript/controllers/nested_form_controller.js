import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "item", "destroyField", "emptyState"]

  connect() {
    this.updateEmptyState()
  }

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.wrapper.insertAdjacentHTML("beforeend", content)
    this.updateEmptyState()
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-nested-form-target='item']")
    const destroy = item.querySelector("[data-nested-form-target='destroyField']")

    if (destroy) {
      destroy.value = "1"
      item.style.display = "none"
    } else {
      item.remove()
    }
    this.updateEmptyState()
  }

  updateEmptyState() {
    const visibleItems = this.itemTargets.filter(item => item.style.display !== "none")
    const emptyState = this.emptyStateTarget

    if (visibleItems.length === 0) {
      emptyState.style.display = "block"
    } else {
      emptyState.style.display = "none"
    }
  }

  get wrapper() {
    return this.element.querySelector(".ingredients-container")
  }
}
