import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "hiddenId"]
  static values = {
    selectedId: Number,
    source: { type: String, default: "foods-data" },
    suffix: { type: String, default: "kcal/100g" }
  }

  connect() {
    this._boundClose = this._onOutsideClick.bind(this)
    this._buildOptions()

    // Pre-fill if editing an existing item
    if (this.selectedIdValue > 0) {
      const food = this._foods?.find(f => f.id === this.selectedIdValue)
      if (food) this.inputTarget.value = food.name
    }
  }

  disconnect() {
    document.removeEventListener("click", this._boundClose)
  }

  // ── Open / filter ───────────────────────────────────────────────

  open() {
    this._positionDropdown()
    this.dropdownTarget.classList.remove("hidden")
    this.filter()
    document.addEventListener("click", this._boundClose)
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    let visibleCount = 0

    this.dropdownTarget.querySelectorAll("[data-combobox-option]").forEach(opt => {
      const match = opt.dataset.name.toLowerCase().includes(query)
      opt.classList.toggle("hidden", !match)
      if (match) visibleCount++
    })

    // Show/hide empty state
    const empty = this.dropdownTarget.querySelector("[data-combobox-empty]")
    if (empty) empty.classList.toggle("hidden", visibleCount > 0)
  }

  // ── Select ──────────────────────────────────────────────────────

  select(event) {
    const opt = event.currentTarget
    this.hiddenIdTarget.value = opt.dataset.id
    this.inputTarget.value = opt.dataset.name
    this.selectedIdValue = parseInt(opt.dataset.id)

    // Notify recipe-builder via native input event
    this.hiddenIdTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this._close()
  }

  // ── Keyboard navigation ─────────────────────────────────────────

  keydown(event) {
    if (event.key === "Escape") {
      this._close()
      return
    }
    if (event.key === "ArrowDown") {
      event.preventDefault()
      const first = this._visibleOptions()[0]
      first?.focus()
      return
    }
    if (event.key === "Enter") {
      event.preventDefault()
      const first = this._visibleOptions()[0]
      first?.click()
    }
  }

  optionKeydown(event) {
    const opts = this._visibleOptions()
    const idx = opts.indexOf(event.currentTarget)

    if (event.key === "ArrowDown") {
      event.preventDefault()
      opts[idx + 1]?.focus()
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      if (idx === 0) this.inputTarget.focus()
      else opts[idx - 1]?.focus()
    } else if (event.key === "Enter") {
      event.preventDefault()
      event.currentTarget.click()
    } else if (event.key === "Escape") {
      this._close()
      this.inputTarget.focus()
    }
  }

  // ── Private ─────────────────────────────────────────────────────

  _buildOptions() {
    const dataEl = document.getElementById(this.sourceValue)
    if (!dataEl) return

    this._foods = JSON.parse(dataEl.textContent)
    const dropdown = this.dropdownTarget
    const suffix = this.suffixValue

    this._foods.forEach(food => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.setAttribute("data-combobox-option", "")
      btn.dataset.id = food.id
      btn.dataset.name = food.name
      btn.className = "w-full text-left px-3 py-2 text-sm text-ink-primary hover:bg-surface-hover transition-colors flex items-center justify-between gap-2"
      btn.innerHTML = `
        <span class="truncate">${food.name}</span>
        <span class="text-xs text-ink-subtle shrink-0">${Math.round(food.calories)} ${suffix}</span>
      `
      btn.addEventListener("click", this.select.bind(this))
      btn.addEventListener("keydown", this.optionKeydown.bind(this))
      dropdown.appendChild(btn)
    })

    // Empty state
    const empty = document.createElement("div")
    empty.setAttribute("data-combobox-empty", "")
    empty.className = "px-3 py-4 text-sm text-ink-subtle text-center hidden"
    empty.textContent = "Aucun aliment trouvé"
    dropdown.appendChild(empty)
  }

  _positionDropdown() {
    const rect = this.inputTarget.getBoundingClientRect()
    const dropdown = this.dropdownTarget
    dropdown.style.position = "fixed"
    dropdown.style.top = `${rect.bottom + 4}px`
    dropdown.style.left = `${rect.left}px`
    dropdown.style.width = `${rect.width}px`
    dropdown.style.zIndex = "9999"
  }

  _close() {
    this.dropdownTarget.classList.add("hidden")
    document.removeEventListener("click", this._boundClose)
  }

  _onOutsideClick(event) {
    if (this.element.contains(event.target)) return
    if (this.dropdownTarget.contains(event.target)) return

    // If input doesn't match a valid selection, reset
    if (!this.selectedIdValue) {
      this.inputTarget.value = ""
    } else {
      const food = this._foods?.find(f => f.id === this.selectedIdValue)
      if (food) this.inputTarget.value = food.name
    }

    this._close()
  }

  _visibleOptions() {
    return Array.from(this.dropdownTarget.querySelectorAll("[data-combobox-option]:not(.hidden)"))
  }
}
