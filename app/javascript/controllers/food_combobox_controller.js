import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "hiddenId"]
  static values = {
    selectedId:     Number,
    source:         { type: String, default: "foods-data" },
    suffix:         { type: String, default: "kcal/100g" },
    noResults:      { type: String, default: "Aucun résultat" },
    recentIds:      { type: Array,  default: [] },
    favoritesLabel: { type: String, default: "Favoris" },
    recentsLabel:   { type: String, default: "Récents" },
    allLabel:       { type: String, default: "Tous" }
  }

  connect() {
    this._boundClose   = this._onOutsideClick.bind(this)
    this._dd           = this.dropdownTarget
    this._optionsBuilt = false

    // Attempt to build options immediately; if the data element isn't ready
    // yet (e.g. Turbo frame race), we'll retry lazily in open().
    this._buildOptions()

    // Pre-fill if editing an existing item
    if (this.selectedIdValue > 0 && this._foods?.length) {
      const food = this._foods.find(f => f.id === this.selectedIdValue)
      if (food) this.inputTarget.value = food.name
    }
  }

  disconnect() {
    document.removeEventListener("click", this._boundClose)
    this._returnToParent()
  }

  // ── Open / filter ───────────────────────────────────────────────

  open() {
    // Lazy build in case connect() ran before the data script was in the DOM
    if (!this._optionsBuilt) this._buildOptions()

    this._portalToBody()
    this._positionDropdown()
    this._dd.classList.remove("hidden")
    this.filter()
    document.addEventListener("click", this._boundClose)
  }

  filter() {
    const query      = this.inputTarget.value.toLowerCase().trim()
    const allOptions = this._dd.querySelectorAll("[data-combobox-option]")
    const allHeaders = this._dd.querySelectorAll("[data-combobox-header]")
    const empty      = this._dd.querySelector("[data-combobox-empty]")

    if (query === "") {
      allOptions.forEach(opt => opt.classList.remove("hidden"))
      allHeaders.forEach(h   => h.classList.remove("hidden"))
      if (empty) empty.classList.add("hidden")
      return
    }

    allHeaders.forEach(h => h.classList.add("hidden"))
    let visibleCount = 0
    allOptions.forEach(opt => {
      const match = opt.dataset.name.toLowerCase().includes(query)
      opt.classList.toggle("hidden", !match)
      if (match) visibleCount++
    })
    if (empty) empty.classList.toggle("hidden", visibleCount > 0)
  }

  // ── Select ──────────────────────────────────────────────────────

  select(event) {
    const opt = event.currentTarget
    this.hiddenIdTarget.value  = opt.dataset.id
    this.inputTarget.value     = opt.dataset.name
    this.selectedIdValue       = parseInt(opt.dataset.id)
    this.hiddenIdTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this._close()
  }

  // ── Keyboard navigation ─────────────────────────────────────────

  keydown(event) {
    if (event.key === "Escape") { this._close(); return }
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this._visibleOptions()[0]?.focus()
      return
    }
    if (event.key === "Enter") {
      event.preventDefault()
      this._visibleOptions()[0]?.click()
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

  // ── Private ─────────────────────────────────────────────────────

  _buildOptions() {
    const dataEl = document.getElementById(this.sourceValue)
    if (!dataEl) return

    let foods
    try {
      foods = JSON.parse(dataEl.textContent)
    } catch (e) {
      return
    }

    this._foods        = foods
    this._optionsBuilt = true

    const dropdown  = this._dd
    const suffix    = this.suffixValue
    const recentIds = this.recentIdsValue || []

    // Clear any previously built options (idempotent rebuild)
    dropdown.innerHTML = ""

    const favorites = foods.filter(f => f.favorite === true)
    const recents   = foods.filter(f => !f.favorite && recentIds.includes(f.id))
                           .sort((a, b) => recentIds.indexOf(a.id) - recentIds.indexOf(b.id))
    const allItems  = foods.filter(f => !f.favorite && !recentIds.includes(f.id))
    const hasSections = favorites.length > 0 || recents.length > 0

    const makeOption = (food) => {
      const btn = document.createElement("button")
      btn.type  = "button"
      btn.setAttribute("data-combobox-option", "")
      btn.dataset.id   = food.id
      btn.dataset.name = food.name
      btn.className    = "w-full text-left px-3 py-2 text-sm text-ink-primary hover:bg-surface-hover transition-colors flex items-center justify-between gap-2"
      const starHtml = food.favorite ? `<i class="fas fa-star text-amber-400 text-xs shrink-0"></i>` : ""
      btn.innerHTML = `
        <span class="flex items-center gap-1.5 min-w-0">
          ${starHtml}<span class="truncate">${food.name}</span>
        </span>
        <span class="text-xs text-ink-subtle shrink-0">${Math.round(food.calories)} ${suffix}</span>
      `
      btn.addEventListener("click",   this.select.bind(this))
      btn.addEventListener("keydown", this.optionKeydown.bind(this))
      return btn
    }

    const appendSection = (labelText, items) => {
      if (items.length === 0) return
      const header = document.createElement("div")
      header.setAttribute("data-combobox-header", labelText)
      header.className  = "px-3 pt-2.5 pb-1 text-[10px] font-semibold tracking-widest uppercase text-ink-subtle/60 select-none"
      header.textContent = labelText
      dropdown.appendChild(header)
      items.forEach(food => dropdown.appendChild(makeOption(food)))
    }

    if (hasSections) {
      appendSection(this.favoritesLabelValue, favorites)
      appendSection(this.recentsLabelValue,   recents)
      appendSection(this.allLabelValue,       allItems)
    } else {
      allItems.forEach(food => dropdown.appendChild(makeOption(food)))
    }

    const empty = document.createElement("div")
    empty.setAttribute("data-combobox-empty", "")
    empty.className  = "px-3 py-4 text-sm text-ink-subtle text-center hidden"
    empty.textContent = this.noResultsValue
    dropdown.appendChild(empty)
  }

  _positionDropdown() {
    const rect = this.inputTarget.getBoundingClientRect()
    this._dd.style.position = "fixed"
    this._dd.style.top      = `${rect.bottom + 4}px`
    this._dd.style.left     = `${rect.left}px`
    this._dd.style.width    = `${rect.width}px`
    this._dd.style.zIndex   = "9999"
  }

  _close() {
    this._dd.classList.add("hidden")
    this._returnToParent()
    document.removeEventListener("click", this._boundClose)
  }

  // Portal: move dropdown to <body> to escape any stacking context (transform, etc.)
  _portalToBody() {
    if (this._dd.parentElement !== document.body) {
      this._ddParent      = this._dd.parentElement
      this._ddNextSibling = this._dd.nextSibling
      document.body.appendChild(this._dd)
    }
  }

  // Restore dropdown to its original DOM position (Turbo cache safety)
  _returnToParent() {
    if (this._ddParent && this._dd && document.body.contains(this._dd)) {
      this._ddParent.insertBefore(this._dd, this._ddNextSibling || null)
    }
  }

  _onOutsideClick(event) {
    if (this.element.contains(event.target)) return
    if (this._dd.contains(event.target))     return

    if (!this.selectedIdValue) {
      this.inputTarget.value = ""
    } else {
      const food = this._foods?.find(f => f.id === this.selectedIdValue)
      if (food) this.inputTarget.value = food.name
    }
    this._close()
  }

  _visibleOptions() {
    return Array.from(this._dd.querySelectorAll("[data-combobox-option]:not(.hidden)"))
  }
}
