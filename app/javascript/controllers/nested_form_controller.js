import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "item", "destroyField", "emptyState", "addButton", "headerRow"]
  static values = { wrapperSelector: { type: String, default: ".ingredients-container" } }

  connect() {
    this.updateEmptyState()
  }

  add(event) {
    event.preventDefault()
    if (!this.wrapper) return
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.wrapper.insertAdjacentHTML("beforeend", content)
    this.updateEmptyState()
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
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
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
  }

  updateEmptyState() {
    const visibleItems = this.itemTargets.filter(item => item.style.display !== "none")
    const isEmpty = visibleItems.length === 0

    this.emptyStateTarget.style.display = isEmpty ? "block" : "none"
    if (this.hasAddButtonTarget) {
      this.addButtonTarget.style.display = isEmpty ? "none" : "flex"
    }
    if (this.hasHeaderRowTarget) {
      this.headerRowTarget.style.display = isEmpty ? "none" : "flex"
    }
  }

  get wrapper() {
    return this.element.querySelector(this.wrapperSelectorValue)
  }
}
