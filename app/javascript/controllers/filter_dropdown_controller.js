import { Controller } from "@hotwired/stimulus"

// Navigation-based filter dropdown.
// Trigger button shows the current active label + chevron.
// Dropdown contains <a> link items — clicking navigates.
export default class extends Controller {
  static targets = ["trigger", "dropdown", "icon", "label"]

  connect() {
    this._handler = null
  }

  toggle(event) {
    event.stopPropagation()
    this.dropdownTarget.classList.contains("hidden") ? this.open() : this.close()
  }

  open() {
    // Close any other open filter dropdowns first
    document.querySelectorAll("[data-filter-dropdown-target='dropdown']").forEach(d => {
      if (d !== this.dropdownTarget) {
        d.classList.add("hidden")
        const icon = d.closest("[data-controller*='filter-dropdown']")
                        ?.querySelector("[data-filter-dropdown-target='icon']")
        if (icon) icon.style.transform = ""
      }
    })

    this.dropdownTarget.classList.remove("hidden")
    if (this.hasIconTarget) this.iconTarget.style.transform = "rotate(180deg)"

    this._handler = (e) => {
      if (!this.element.contains(e.target)) this.close()
    }
    document.addEventListener("click", this._handler)
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    if (this.hasIconTarget) this.iconTarget.style.transform = ""
    if (this._handler) {
      document.removeEventListener("click", this._handler)
      this._handler = null
    }
  }

  disconnect() {
    if (this._handler) document.removeEventListener("click", this._handler)
  }
}
