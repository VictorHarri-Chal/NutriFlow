import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "item", "destroyField", "emptyState", "addButton", "headerRow", "maxHint", "submitButton"]
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
    const carry = this._captureCarryOver()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.wrapper.insertAdjacentHTML("beforeend", content)
    this._applyCarryOver(carry)
    this.updateEmptyState()
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
  }

  // Copy values of [data-carry-over] fields from the last visible item so a new
  // item pre-fills from the previous one (e.g. reps/weight on a program set).
  _captureCarryOver() {
    const items = Array.from(this.wrapper.querySelectorAll("[data-nested-form-target='item']"))
                       .filter(item => item.style.display !== "none")
    const last = items[items.length - 1]
    if (!last) return null
    const values = {}
    last.querySelectorAll("[data-carry-over]").forEach(el => { values[el.dataset.carryOver] = el.value })
    return values
  }

  _applyCarryOver(values) {
    if (!values) return
    const items = this.wrapper.querySelectorAll("[data-nested-form-target='item']")
    const newItem = items[items.length - 1]
    if (!newItem) return
    newItem.querySelectorAll("[data-carry-over]").forEach(el => {
      const v = values[el.dataset.carryOver]
      if (v != null && v !== "") el.value = v
    })
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
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = isEmpty
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
