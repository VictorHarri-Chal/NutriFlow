import { Controller } from "@hotwired/stimulus"

// Autocomplete for shopping list item add form.
// Shows a sectioned dropdown (favorites first, then all) on focus.
// Also accepts free-text entries — food_id is cleared when typing freely.
export default class extends Controller {
  static targets = ["input", "dropdown", "hiddenFoodId", "hiddenCategory"]
  static values  = {
    foods:          Array,
    noResults:      { type: String, default: "Appuyez sur Entrée pour ajouter" },
    favoritesLabel: { type: String, default: "Favoris" },
    allLabel:       { type: String, default: "Tous les aliments" }
  }

  connect() {
    this._boundClose = this._onOutsideClick.bind(this)
    this._dd         = this.dropdownTarget
    this._buildOptions()
  }

  disconnect() {
    document.removeEventListener("click", this._boundClose)
  }

  // ── Open on focus ───────────────────────────────────────────────

  focus() {
    this._dd.classList.remove("hidden")
    this._applyFilter(this.inputTarget.value.trim())
    document.addEventListener("click", this._boundClose)
  }

  // ── Input handling ──────────────────────────────────────────────

  input() {
    const query = this.inputTarget.value.trim()
    // Clear food selection when user types freely
    this.hiddenFoodIdTarget.value = ""
    if (this.hasHiddenCategoryTarget) this.hiddenCategoryTarget.value = ""

    this._dd.classList.remove("hidden")
    document.addEventListener("click", this._boundClose)
    this._applyFilter(query)
  }

  keydown(event) {
    if (event.key === "Escape") { this._close(); return }
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this._visibleOptions()[0]?.focus()
      return
    }
    if (event.key === "Enter") {
      event.preventDefault()
      const first = this._visibleOptions()[0]
      if (first) {
        first.click()
      } else {
        // Free-text submit: close dropdown and let form submit naturally
        this._close()
        this.element.closest("form")?.requestSubmit()
      }
    }
  }

  optionKeydown(event) {
    const opts = this._visibleOptions()
    const idx  = opts.indexOf(event.currentTarget)
    if (event.key === "ArrowDown") {
      event.preventDefault(); opts[idx + 1]?.focus()
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      idx === 0 ? this.inputTarget.focus() : opts[idx - 1]?.focus()
    } else if (event.key === "Enter") {
      event.preventDefault(); event.currentTarget.click()
    } else if (event.key === "Escape") {
      this._close(); this.inputTarget.focus()
    }
  }

  // ── Option selection ────────────────────────────────────────────

  select(event) {
    const opt = event.currentTarget
    this.inputTarget.value        = opt.dataset.name
    this.hiddenFoodIdTarget.value = opt.dataset.id
    if (this.hasHiddenCategoryTarget) {
      this.hiddenCategoryTarget.value = opt.dataset.category || ""
    }
    this._close()
    // Focus the quantity number input if present
    this.element.closest("form")?.querySelector("[data-quantity-input] input[type='number']")?.focus()
  }

  // ── Private ─────────────────────────────────────────────────────

  _buildOptions() {
    const dropdown = this._dd
    dropdown.innerHTML = ""

    const foods     = this.foodsValue
    const favorites = foods.filter(f => f.favorite === true)
    const rest      = foods.filter(f => f.favorite !== true)

    const makeOption = (food) => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.setAttribute("data-shopping-autocomplete-option", "")
      btn.dataset.id       = food.id
      btn.dataset.name     = food.name
      btn.dataset.category = food.category || ""
      btn.className = "w-full text-left px-3 py-2 text-sm text-ink-primary hover:bg-surface-hover transition-colors flex items-center gap-1.5"

      const starHtml = food.favorite
        ? `<i class="fas fa-star text-amber-400 text-xs shrink-0"></i>`
        : `<span class="w-3 shrink-0"></span>`

      btn.innerHTML = `${starHtml}<span class="truncate">${food.name}</span>`
      btn.addEventListener("click",   this.select.bind(this))
      btn.addEventListener("keydown", this.optionKeydown.bind(this))
      return btn
    }

    const appendSection = (labelText, items) => {
      if (items.length === 0) return
      const header = document.createElement("div")
      header.setAttribute("data-shopping-section-header", "")
      header.className = "px-3 pt-2.5 pb-1 text-[10px] font-semibold tracking-widest uppercase text-ink-subtle/60 select-none"
      header.textContent = labelText
      dropdown.appendChild(header)
      items.forEach(food => dropdown.appendChild(makeOption(food)))
    }

    const hasSections = favorites.length > 0
    if (hasSections) {
      appendSection(this.favoritesLabelValue, favorites)
      appendSection(this.allLabelValue, rest)
    } else {
      rest.forEach(food => dropdown.appendChild(makeOption(food)))
    }

    // Empty / free-text hint
    const empty = document.createElement("div")
    empty.setAttribute("data-shopping-empty", "")
    empty.className = "px-3 py-3 text-sm text-ink-subtle text-center hidden"
    empty.textContent = this.noResultsValue
    dropdown.appendChild(empty)
  }

  _applyFilter(query) {
    const options = this._dd.querySelectorAll("[data-shopping-autocomplete-option]")
    const headers = this._dd.querySelectorAll("[data-shopping-section-header]")
    const empty   = this._dd.querySelector("[data-shopping-empty]")

    if (query === "") {
      // Restore sectioned view
      options.forEach(opt => opt.classList.remove("hidden"))
      headers.forEach(h   => h.classList.remove("hidden"))
      if (empty) empty.classList.add("hidden")
      return
    }

    // Searching: collapse section headers, show only matching options
    headers.forEach(h => h.classList.add("hidden"))

    const q = query.toLowerCase()
    let visible = 0
    options.forEach(opt => {
      const match = opt.dataset.name.toLowerCase().includes(q)
      opt.classList.toggle("hidden", !match)
      if (match) visible++
    })

    if (empty) empty.classList.toggle("hidden", visible > 0)
  }

  _close() {
    this._dd.classList.add("hidden")
    document.removeEventListener("click", this._boundClose)
  }

  _onOutsideClick(event) {
    if (this.element.contains(event.target)) return
    if (this._dd.contains(event.target))     return
    this._close()
  }

  _visibleOptions() {
    return Array.from(
      this._dd.querySelectorAll("[data-shopping-autocomplete-option]:not(.hidden)")
    )
  }
}
