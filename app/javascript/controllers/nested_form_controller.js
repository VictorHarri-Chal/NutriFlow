import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "item", "destroyField", "emptyState", "addButton", "headerRow", "maxHint"]
  // maxItems: 0 means unlimited — only the program-builder set editor opts into a cap.
  static values = {
    wrapperSelector: { type: String, default: ".ingredients-container" },
    maxItems:        { type: Number, default: 0 }
  }

  connect() {
    this.updateEmptyState()
  }

  add(event) {
    event.preventDefault()
    if (!this.wrapper) return
    if (this.maxItemsValue > 0 && this.visibleItemCount >= this.maxItemsValue) return
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.wrapper.insertAdjacentHTML("beforeend", content)
    this.updateEmptyState()
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
  }

  // The quantity field has no combobox/keydown handling of its own (unlike the
  // food-name input) — without this, pressing Enter while editing a quantity
  // submits the enclosing form instead of just confirming the row's value.
  preventEnterSubmit(event) {
    event.preventDefault()
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
    const visibleCount = this.visibleItemCount
    const isEmpty = visibleCount === 0

    this.emptyStateTarget.style.display = isEmpty ? "block" : "none"
    if (this.hasAddButtonTarget) {
      this.addButtonTarget.style.display = isEmpty ? "none" : "flex"
    }
    if (this.hasHeaderRowTarget) {
      this.headerRowTarget.style.display = isEmpty ? "none" : "flex"
    }

    if (this.maxItemsValue > 0) {
      const atMax = visibleCount >= this.maxItemsValue
      if (this.hasAddButtonTarget) {
        this.addButtonTarget.classList.toggle("opacity-30", atMax)
        this.addButtonTarget.classList.toggle("pointer-events-none", atMax)
      }
      if (this.hasMaxHintTarget) this.maxHintTarget.classList.toggle("hidden", !atMax)
    }
  }

  get visibleItemCount() {
    return this.itemTargets.filter(item => item.style.display !== "none").length
  }

  get wrapper() {
    return this.element.querySelector(this.wrapperSelectorValue)
  }
}
