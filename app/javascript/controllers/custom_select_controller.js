import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "label", "dropdown"]

  connect() {
    this.buildDropdown()
    this.syncLabel()
  }

  // Build custom dropdown items from native <select> options
  buildDropdown() {
    const dropdown = this.dropdownTarget
    dropdown.innerHTML = ""

    Array.from(this.selectTarget.options).forEach(opt => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.dataset.action = "click->custom-select#choose"
      btn.dataset.value = opt.value
      btn.textContent = opt.text

      const isSelected = opt.value === this.selectTarget.value
      btn.className = [
        "w-full text-left px-3 py-2 text-sm transition-colors flex items-center justify-between gap-2",
        isSelected
          ? "bg-brand/10 text-brand font-medium"
          : "text-ink-primary hover:bg-surface-hover"
      ].join(" ")

      if (isSelected) {
        const check = document.createElement("i")
        check.className = "fas fa-check text-xs text-brand flex-shrink-0"
        btn.appendChild(check)
      }

      dropdown.appendChild(btn)
    })
  }

  syncLabel() {
    const sel = this.selectTarget
    const opt = sel.options[sel.selectedIndex]
    const hasValue = sel.value !== ""
    this.labelTarget.textContent = opt ? opt.text : "—"
    this.labelTarget.classList.remove("text-ink-primary", "text-ink-subtle")
    this.labelTarget.classList.add(hasValue ? "text-ink-primary" : "text-ink-subtle")
  }

  toggle(event) {
    event.stopPropagation()
    this.dropdownTarget.classList.contains("hidden") ? this.open() : this.close()
  }

  open() {
    // Close any other open dropdowns
    document.querySelectorAll("[data-custom-select-dropdown]").forEach(d => {
      if (d !== this.dropdownTarget) d.classList.add("hidden")
    })

    this.dropdownTarget.classList.remove("hidden")
    this._handler = (e) => { if (!this.element.contains(e.target)) this.close() }
    document.addEventListener("click", this._handler)
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    if (this._handler) {
      document.removeEventListener("click", this._handler)
      this._handler = null
    }
  }

  choose(event) {
    const value = event.currentTarget.dataset.value
    this.selectTarget.value = value
    // Dispatch change so any other listeners are aware
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.syncLabel()
    this.buildDropdown()
    this.close()
  }

  disconnect() {
    if (this._handler) document.removeEventListener("click", this._handler)
  }
}
