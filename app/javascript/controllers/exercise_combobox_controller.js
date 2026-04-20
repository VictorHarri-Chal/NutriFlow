import { Controller } from "@hotwired/stimulus"

// Lightweight AJAX exercise search combobox.
// Opens on focus, searches on input (debounced), dispatches "exercise-selected" on pick.
export default class extends Controller {
  static targets = ["input", "dropdown", "hiddenId"]
  static values = {
    searchPath: String,
    noResults:  { type: String, default: "Aucun résultat" },
    hint:       { type: String, default: "Tapez pour rechercher un exercice" }
  }

  connect() {
    this._boundClose    = this._onOutsideClick.bind(this)
    this._debounceTimer = null
  }

  disconnect() {
    document.removeEventListener("click", this._boundClose)
    clearTimeout(this._debounceTimer)
  }

  // ── Open on focus ─────────────────────────────────────────────────

  open() {
    const query = this.inputTarget.value.trim()
    if (query.length >= 2) {
      clearTimeout(this._debounceTimer)
      this._search(query)
    } else {
      this._showHint()
    }
  }

  // ── Input / search ────────────────────────────────────────────────

  input() {
    clearTimeout(this._debounceTimer)
    const query = this.inputTarget.value.trim()
    if (query.length < 2) {
      this._showHint()
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
    if (event.key === "ArrowDown")       { event.preventDefault(); opts[idx + 1]?.focus() }
    else if (event.key === "ArrowUp")    { event.preventDefault(); idx === 0 ? this.inputTarget.focus() : opts[idx - 1]?.focus() }
    else if (event.key === "Enter")      { event.preventDefault(); event.currentTarget.click() }
    else if (event.key === "Escape")     { this._close(); this.inputTarget.focus() }
  }

  // ── Select ────────────────────────────────────────────────────────

  select(event) {
    const opt = event.currentTarget
    if (this.hasHiddenIdTarget) this.hiddenIdTarget.value = opt.dataset.id

    // Dispatch to parent workout-form controller
    this.element.dispatchEvent(new CustomEvent("exercise-selected", {
      bubbles: true,
      detail: { id: opt.dataset.id, name: opt.dataset.name }
    }))

    this._close()
    this.inputTarget.value = ""
    if (this.hasHiddenIdTarget) this.hiddenIdTarget.value = ""
  }

  // ── Private ───────────────────────────────────────────────────────

  _showHint() {
    this.dropdownTarget.innerHTML = `
      <div class="px-3 py-4 text-sm text-ink-subtle text-center flex flex-col items-center gap-1.5">
        <i class="fas fa-dumbbell text-xs text-ink-subtle/50"></i>
        <span>${this.hintValue}</span>
      </div>
    `
    this._open()
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
    this.dropdownTarget.innerHTML = ""

    if (exercises.length === 0) {
      const empty = document.createElement("div")
      empty.className = "px-3 py-4 text-sm text-ink-subtle text-center"
      empty.textContent = this.noResultsValue
      this.dropdownTarget.appendChild(empty)
    } else {
      exercises.forEach(ex => {
        const btn = document.createElement("button")
        btn.type = "button"
        btn.dataset.id   = ex.id
        btn.dataset.name = ex.name
        btn.className = "w-full text-left px-3 py-2 text-sm text-ink-primary hover:bg-surface-hover transition-colors flex items-center justify-between gap-2"

        const nameSpan = document.createElement("span")
        nameSpan.className = "truncate capitalize"
        nameSpan.textContent = ex.name

        const partSpan = document.createElement("span")
        partSpan.className = "text-xs text-ink-subtle shrink-0"
        partSpan.textContent = ex.body_part_label || ""

        btn.appendChild(nameSpan)
        btn.appendChild(partSpan)

        btn.addEventListener("click",   this.select.bind(this))
        btn.addEventListener("keydown", this.optionKeydown.bind(this))
        this.dropdownTarget.appendChild(btn)
      })
    }

    this._open()
  }

  _open() {
    this._positionDropdown()
    this.dropdownTarget.classList.remove("hidden")
    document.removeEventListener("click", this._boundClose)
    document.addEventListener("click", this._boundClose)
  }

  _close() {
    this.dropdownTarget.classList.add("hidden")
    document.removeEventListener("click", this._boundClose)
  }

  _positionDropdown() {
    const rect = this.inputTarget.getBoundingClientRect()
    const d    = this.dropdownTarget
    d.style.position = "fixed"
    d.style.top      = `${rect.bottom + 4}px`
    d.style.left     = `${rect.left}px`
    d.style.width    = `${rect.width}px`
    d.style.zIndex   = "9999"
  }

  _onOutsideClick(event) {
    if (this.element.contains(event.target))        return
    if (this.dropdownTarget.contains(event.target)) return
    this._close()
  }

  _visibleOptions() {
    return Array.from(this.dropdownTarget.querySelectorAll("button:not(.hidden)"))
  }
}
