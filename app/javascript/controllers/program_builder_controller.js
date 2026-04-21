import { Controller } from "@hotwired/stimulus"

// Controls the exercise search combobox inside a program day column.
// Submits via fetch (Turbo) to ProgramExercisesController#create.
export default class extends Controller {
  static targets = ["input", "dropdown", "hiddenId", "addRow"]
  static values  = {
    searchPath:     String,
    createPath:     String,
    noResults:      String,
    favoritesPath:  String,
    favoritesLabel: String,
  }

  // ── State ────────────────────────────────────────────────────────────────
  #debounce    = null
  #highlighted = -1

  // ── Lifecycle ────────────────────────────────────────────────────────────
  connect() {
    this._handleOutsideClick = this._onOutsideClick.bind(this)
    document.addEventListener("click", this._handleOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this._handleOutsideClick)
  }

  // ── Public actions ───────────────────────────────────────────────────────
  open() {
    if (this.inputTarget.value.trim() === "") {
      this._showFavorites()
    }
  }

  input() {
    clearTimeout(this.#debounce)
    const q = this.inputTarget.value.trim()
    if (q === "") { this._showFavorites(); return }
    this.#debounce = setTimeout(() => this._search(q), 200)
  }

  keydown(e) {
    const items = this.dropdownTarget.querySelectorAll("[data-exercise-id]")
    if (e.key === "ArrowDown") { e.preventDefault(); this._move(items, 1) }
    else if (e.key === "ArrowUp") { e.preventDefault(); this._move(items, -1) }
    else if (e.key === "Enter") { e.preventDefault(); if (this.#highlighted >= 0) items[this.#highlighted]?.click() }
    else if (e.key === "Escape") { this._close() }
  }

  select(e) {
    const item = e.currentTarget
    const exerciseId = item.dataset.exerciseId
    const name       = item.dataset.name

    // Avoid duplicates within same day
    const existing = this.element.querySelectorAll(`[data-pe-exercise-id="${exerciseId}"]`)
    if (existing.length > 0) { this._close(); this._reset(); return }

    this._submitCreate(exerciseId, name)
  }

  // ── Private ─────────────────────────────────────────────────────────────
  async _showFavorites() {
    if (!this.hasFavoritesPathValue) { this._renderItems([]); return }
    try {
      const res  = await fetch(this.favoritesPathValue, { headers: { Accept: "application/json" } })
      const data = await res.json()
      this._renderItems(data, this.favoritesLabelValue)
    } catch { this._renderItems([]) }
  }

  async _search(q) {
    try {
      const res  = await fetch(`${this.searchPathValue}?query=${encodeURIComponent(q)}`, { headers: { Accept: "application/json" } })
      const data = await res.json()
      this._renderItems(data)
    } catch { this._renderItems([]) }
  }

  _positionDropdown() {
    const rect       = this.inputTarget.getBoundingClientRect()
    const spaceAbove = rect.top
    const spaceBelow = window.innerHeight - rect.bottom
    const el         = this.dropdownTarget

    el.style.position = "fixed"
    el.style.left     = `${rect.left}px`
    el.style.width    = `${Math.max(rect.width, 260)}px`
    el.style.zIndex   = "9999"

    if (spaceAbove >= 100 || spaceAbove >= spaceBelow) {
      // Show ABOVE: pin the BOTTOM edge to the input's top (stays attached regardless of item count)
      el.style.bottom    = `${window.innerHeight - rect.top + 4}px`
      el.style.top       = ""
      el.style.maxHeight = `${Math.min(280, spaceAbove - 12)}px`
    } else {
      // Show BELOW: pin the TOP edge to the input's bottom
      el.style.top       = `${rect.bottom + 4}px`
      el.style.bottom    = ""
      el.style.maxHeight = `${Math.min(280, spaceBelow - 12)}px`
    }
  }

  _renderItems(items, label = null) {
    this.dropdownTarget.innerHTML = ""
    this._positionDropdown()
    this.dropdownTarget.classList.remove("hidden")
    this.#highlighted = -1

    if (label) {
      const h = document.createElement("div")
      h.className = "px-3 pt-2 pb-1 text-[10px] font-semibold uppercase tracking-wider text-ink-subtle/60"
      h.textContent = label
      this.dropdownTarget.appendChild(h)
    }

    if (items.length === 0) {
      const el = document.createElement("div")
      el.className = "px-3 py-2 text-xs text-ink-subtle/60 italic"
      el.textContent = this.noResultsValue
      this.dropdownTarget.appendChild(el)
      return
    }

    items.forEach(item => {
      const el = document.createElement("div")
      el.className = "flex items-center gap-2 px-3 py-2 cursor-pointer hover:bg-surface-hover text-sm text-ink-primary transition-colors"
      el.dataset.exerciseId = item.id
      el.dataset.name       = item.name
      el.dataset.action     = "click->program-builder#select"
      el.innerHTML = `
        <span class="flex-1 truncate">${item.name}</span>
        <span class="text-[10px] text-ink-subtle/60 shrink-0">${item.body_part_label || ""}</span>
      `
      this.dropdownTarget.appendChild(el)
    })
  }

  _move(items, dir) {
    if (items.length === 0) return
    items[this.#highlighted]?.classList.remove("bg-surface-hover")
    this.#highlighted = Math.max(0, Math.min(items.length - 1, this.#highlighted + dir))
    items[this.#highlighted].classList.add("bg-surface-hover")
    items[this.#highlighted].scrollIntoView({ block: "nearest" })
  }

  async _submitCreate(exerciseId, name) {
    this._close()
    this._reset()

    const form = new FormData()
    form.append("program_exercise[exercise_id]", exerciseId)
    form.append("program_exercise[sets]", 3)
    form.append("program_exercise[reps_target]", 10)

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    await fetch(this.createPathValue, {
      method:  "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        Accept: "text/vnd.turbo-stream.html, text/html",
      },
      body: form,
    }).then(r => r.text()).then(html => {
      if (html.includes("turbo-stream")) {
        document.querySelector("turbo-stream-source") // hint turbo to process
        Turbo.renderStreamMessage(html)
      }
    })
  }

  _close() {
    this.dropdownTarget.classList.add("hidden")
    this.dropdownTarget.innerHTML = ""
    this.#highlighted = -1
  }

  _reset() {
    this.inputTarget.value = ""
  }

  _onOutsideClick(e) {
    if (!this.element.contains(e.target)) this._close()
  }
}
