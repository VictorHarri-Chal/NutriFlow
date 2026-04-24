import { Controller } from "@hotwired/stimulus"

// Exercise combobox with favorites + recents sections.
// Opens on focus:
//   - empty query → shows "Favoris" section + "Récents" section then hint to type
//   - ≥2 chars    → AJAX search (with star on favorited results)
export default class extends Controller {
  static targets = ["input", "dropdown", "hiddenId"]
  static values = {
    searchPath:     String,
    favoritesPath:  String,
    recentsPath:    String,
    noResults:      { type: String, default: "Aucun résultat" },
    hint:           { type: String, default: "Tapez pour rechercher un exercice" },
    favoritesLabel: { type: String, default: "Favoris" },
    recentsLabel:   { type: String, default: "Récents" }
  }

  connect() {
    this._boundClose    = this._onOutsideClick.bind(this)
    this._debounceTimer = null
    this._favorites     = null  // cached after first fetch
    this._recents       = null  // cached after first fetch
    this._dd            = this.dropdownTarget
  }

  disconnect() {
    document.removeEventListener("click", this._boundClose)
    clearTimeout(this._debounceTimer)
    this._returnToParent()
  }

  // ── Open on focus ─────────────────────────────────────────────────

  async open() {
    const query = this.inputTarget.value.trim()
    if (query.length >= 2) {
      clearTimeout(this._debounceTimer)
      this._search(query)
    } else {
      await this._showFavoritesAndRecents()
    }
  }

  // ── Input / search ────────────────────────────────────────────────

  input() {
    clearTimeout(this._debounceTimer)
    const query = this.inputTarget.value.trim()
    if (query.length < 2) {
      this._showFavoritesAndRecents()
      return
    }
    this._debounceTimer = setTimeout(() => this._search(query), 250)
  }

  // ── Keyboard navigation ───────────────────────────────────────────

  keydown(event) {
    if (event.key === "Escape") { this._close(); return }
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this._visibleOptions()[0]?.focus()
    }
    if (event.key === "Enter") {
      event.preventDefault()
      this._visibleOptions()[0]?.click()
    }
  }

  optionKeydown(event) {
    const opts = this._visibleOptions()
    const idx  = opts.indexOf(event.currentTarget)
    if (event.key === "ArrowDown")    { event.preventDefault(); opts[idx + 1]?.focus() }
    else if (event.key === "ArrowUp") { event.preventDefault(); idx === 0 ? this.inputTarget.focus() : opts[idx - 1]?.focus() }
    else if (event.key === "Enter")   { event.preventDefault(); event.currentTarget.click() }
    else if (event.key === "Escape")  { this._close(); this.inputTarget.focus() }
  }

  // ── Select ────────────────────────────────────────────────────────

  select(event) {
    const opt = event.currentTarget
    if (this.hasHiddenIdTarget) this.hiddenIdTarget.value = opt.dataset.id

    this.element.dispatchEvent(new CustomEvent("exercise-selected", {
      bubbles: true,
      detail: { id: opt.dataset.id, name: opt.dataset.name }
    }))

    this._close()
    this.inputTarget.value = ""
    if (this.hasHiddenIdTarget) this.hiddenIdTarget.value = ""
  }

  // ── Private ───────────────────────────────────────────────────────

  async _showFavoritesAndRecents() {
    // Fetch both in parallel if not cached
    const promises = []
    if (!this._favorites) {
      promises.push(
        fetch(this.favoritesPathValue, { headers: { Accept: "application/json" } })
          .then(r => r.json())
          .then(data => { this._favorites = data })
          .catch(() => { this._favorites = [] })
      )
    }
    if (this.hasRecentsPathValue && !this._recents) {
      promises.push(
        fetch(this.recentsPathValue, { headers: { Accept: "application/json" } })
          .then(r => r.json())
          .then(data => { this._recents = data })
          .catch(() => { this._recents = [] })
      )
    }
    if (promises.length > 0) await Promise.all(promises)

    this._dd.innerHTML = ""

    const favorites = this._favorites || []
    const recents   = (this._recents  || []).filter(r => !favorites.some(f => f.id === r.id))

    if (favorites.length > 0) {
      this._dd.appendChild(this._makeHeader(this.favoritesLabelValue))
      favorites.forEach(ex => this._dd.appendChild(this._makeOption(ex)))
    }

    if (recents.length > 0) {
      if (favorites.length > 0) {
        const sep = document.createElement("div")
        sep.className = "mx-3 my-1 border-t border-surface-border/30"
        this._dd.appendChild(sep)
      }
      this._dd.appendChild(this._makeHeader(this.recentsLabelValue))
      recents.forEach(ex => this._dd.appendChild(this._makeOption(ex)))
    }

    if (favorites.length > 0 || recents.length > 0) {
      const sep = document.createElement("div")
      sep.className = "mx-3 my-1.5 border-t border-surface-border/30"
      this._dd.appendChild(sep)
    }

    // Hint to type
    const hint = document.createElement("div")
    hint.className = "px-3 py-3 text-sm text-ink-subtle text-center flex flex-col items-center gap-1.5"
    hint.innerHTML = `<i class="fas fa-search text-xs text-ink-subtle/50"></i><span>${this.hintValue}</span>`
    this._dd.appendChild(hint)

    this._open()
  }

  _makeHeader(label) {
    const header = document.createElement("div")
    header.className = "px-3 pt-2.5 pb-1 text-[10px] font-semibold tracking-widest uppercase text-ink-subtle/60 select-none"
    header.textContent = label
    return header
  }

  async _search(query) {
    const url = `${this.searchPathValue}?query=${encodeURIComponent(query)}&limit=10`
    try {
      const res     = await fetch(url, { headers: { Accept: "application/json" } })
      const results = await res.json()
      this._renderResults(results)
    } catch (_) {}
  }

  _renderResults(exercises) {
    this._dd.innerHTML = ""

    if (exercises.length === 0) {
      const empty = document.createElement("div")
      empty.className = "px-3 py-4 text-sm text-ink-subtle text-center"
      empty.textContent = this.noResultsValue
      this._dd.appendChild(empty)
    } else {
      exercises.forEach(ex => this._dd.appendChild(this._makeOption(ex)))
    }

    this._open()
  }

  _makeOption(ex) {
    const btn = document.createElement("button")
    btn.type = "button"
    btn.dataset.id   = ex.id
    btn.dataset.name = ex.name
    btn.className = "w-full text-left px-3 py-2 text-sm text-ink-primary hover:bg-surface-hover transition-colors flex items-center justify-between gap-2"

    const starHtml = ex.favorite
      ? `<i class="fas fa-star text-amber-400 text-xs shrink-0"></i>`
      : ""

    const left = document.createElement("span")
    left.className = "flex items-center gap-1.5 min-w-0"
    left.innerHTML = `${starHtml}<span class="truncate capitalize">${ex.name}</span>`

    const right = document.createElement("span")
    right.className = "text-xs text-ink-subtle shrink-0"
    right.textContent = ex.body_part_label || ""

    btn.appendChild(left)
    btn.appendChild(right)
    btn.addEventListener("click",   this.select.bind(this))
    btn.addEventListener("keydown", this.optionKeydown.bind(this))
    return btn
  }

  _open() {
    this._portalToBody()
    this._positionDropdown()
    this._dd.classList.remove("hidden")
    document.removeEventListener("click", this._boundClose)
    document.addEventListener("click", this._boundClose)
  }

  _close() {
    this._dd.classList.add("hidden")
    this._returnToParent()
    document.removeEventListener("click", this._boundClose)
  }

  // Portal: move dropdown to <body> on open to escape any stacking context.
  _portalToBody() {
    if (this._dd.parentElement !== document.body) {
      this._ddParent = this._dd.parentElement
      this._ddNextSibling = this._dd.nextSibling
      document.body.appendChild(this._dd)
    }
  }

  // Restore dropdown to its original DOM position (Turbo cache safety).
  _returnToParent() {
    if (this._ddParent && document.body.contains(this._dd)) {
      this._ddParent.insertBefore(this._dd, this._ddNextSibling || null)
    }
  }

  _positionDropdown() {
    const rect = this.inputTarget.getBoundingClientRect()
    this._dd.style.position = "fixed"
    this._dd.style.top      = `${rect.bottom + 4}px`
    this._dd.style.left     = `${rect.left}px`
    this._dd.style.width    = `${rect.width}px`
    this._dd.style.zIndex   = "9999"
  }

  _onOutsideClick(event) {
    if (this.element.contains(event.target)) return
    if (this._dd.contains(event.target))     return
    this._close()
  }

  _visibleOptions() {
    return Array.from(this._dd.querySelectorAll("button:not(.hidden)"))
  }
}
