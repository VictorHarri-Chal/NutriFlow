import { Controller } from "@hotwired/stimulus"

const VALID_NUTRISCORE = new Set(["a", "b", "c", "d", "e"])

const NUTRISCORE_LABELS = {
  a: "Nutri-Score A — Excellente qualité nutritionnelle",
  b: "Nutri-Score B — Bonne qualité nutritionnelle",
  c: "Nutri-Score C — Qualité nutritionnelle moyenne",
  d: "Nutri-Score D — Qualité nutritionnelle insuffisante",
  e: "Nutri-Score E — Mauvaise qualité nutritionnelle"
}

export default class extends Controller {
  static targets = [
    "input", "results", "searchIcon",
    "typeHint", "emptyState", "emptyFilter",
    "offIdField", "nutriscoreField", "novaGroupField",
    "badge", "ciqualBadge",
    "filterBtn"
  ]
  static values = { url: String }

  connect() {
    this._timeout     = null
    this._products    = new Map()
    this._allProducts = []
    this._hasSearched = false
    this._filter      = "all"
  }

  disconnect() {
    clearTimeout(this._timeout)
  }

  search() {
    clearTimeout(this._timeout)
    const q = this.inputTarget.value.trim()
    if (q.length < 2) {
      this._reset()
      return
    }
    this._timeout = setTimeout(() => this._fetch(q), 300)
  }

  setFilter({ params: { filter } }) {
    this._filter = filter
    this._updateFilterBtns()
    if (this._hasSearched) {
      this._renderResults(this._allProducts)
    }
  }

  selectProduct({ params: { index } }) {
    const product = this._products.get(String(index))
    if (!product) return

    if (product.source === "off") {
      this.offIdFieldTarget.value      = product.off_id     || ""
      this.nutriscoreFieldTarget.value = product.nutriscore || ""
      this.novaGroupFieldTarget.value  = product.nova_group || ""
      if (this.hasCiqualBadgeTarget) this.ciqualBadgeTarget.classList.replace("flex", "hidden")
      if (this.hasBadgeTarget)       this.badgeTarget.classList.replace("hidden", "flex")
    } else {
      this.offIdFieldTarget.value      = ""
      this.nutriscoreFieldTarget.value = ""
      this.novaGroupFieldTarget.value  = ""
      if (this.hasBadgeTarget)       this.badgeTarget.classList.replace("flex", "hidden")
      if (this.hasCiqualBadgeTarget) this.ciqualBadgeTarget.classList.replace("hidden", "flex")
    }

    document.dispatchEvent(new CustomEvent("food-off-search:import", {
      detail: { product },
      bubbles: true
    }))

    const manualTab = document.querySelector("[data-tab='manual']")
    if (manualTab) manualTab.click()
  }

  async _fetch(query) {
    this._showSpinner()
    this._hasSearched = true
    try {
      const res  = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`)
      const data = await res.json()
      this._renderResults(data.products || [])
    } catch {
      this._reset()
    } finally {
      this._hideSpinner()
    }
  }

  _renderResults(products) {
    this._allProducts = products

    const filtered = this._filter === "all"
      ? products
      : products.filter(p => p.source === this._filter)

    this._products.clear()
    this.resultsTarget.innerHTML = ""

    if (filtered.length === 0) {
      this.resultsTarget.classList.add("hidden")
      this.typeHintTarget.classList.add("hidden")
      if (products.length > 0) {
        this.emptyFilterTarget.classList.remove("hidden")
        this.emptyStateTarget.classList.add("hidden")
      } else {
        this.emptyStateTarget.classList.remove("hidden")
        this.emptyFilterTarget.classList.add("hidden")
      }
      return
    }

    this.emptyStateTarget.classList.add("hidden")
    this.emptyFilterTarget.classList.add("hidden")
    this.typeHintTarget.classList.add("hidden")
    this.resultsTarget.classList.remove("hidden")

    filtered.forEach((product, i) => {
      this._products.set(String(i), product)
      const wrapper = document.createElement("div")
      wrapper.innerHTML = this._productHTML(product, i)
      this.resultsTarget.appendChild(wrapper.firstElementChild)
    })
  }

  _productHTML(product, index) {
    const img = product.image_url
      ? `<img src="${product.image_url}" alt="" class="w-full h-full object-cover" loading="lazy">`
      : `<i class="fas fa-bowl-food text-surface-border text-sm"></i>`

    const sourceBadge = product.source === "ciqual"
      ? `<span class="shrink-0 text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-full bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">Générique</span>`
      : `<span class="shrink-0 text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-full bg-blue-500/15 text-blue-400 border border-blue-500/30">Emballé</span>`

    const grade = product.nutriscore?.toLowerCase()
    const nutriscore = grade && VALID_NUTRISCORE.has(grade)
      ? `<span class="w-7 h-7 rounded-lg flex items-center justify-center text-white text-xs font-bold uppercase shrink-0 ${this._nutriscoreColor(grade)}" data-tooltip="${NUTRISCORE_LABELS[grade]}">${grade.toUpperCase()}</span>`
      : ""

    const subtitle = product.brand || product.category
    const brand = subtitle
      ? `<div class="text-xs text-ink-muted truncate">${this._escape(subtitle)}</div>`
      : ""

    return `
      <button type="button"
              class="w-full flex items-center gap-3 px-4 py-3 hover:bg-surface-hover transition-colors text-left group"
              data-action="click->food-off-search#selectProduct"
              data-food-off-search-index-param="${index}">
        <div class="w-10 h-10 rounded-lg bg-surface-base border border-surface-border/40 overflow-hidden shrink-0 flex items-center justify-center">
          ${img}
        </div>
        <div class="flex-1 min-w-0">
          <div class="font-medium text-ink-primary text-sm truncate group-hover:text-brand transition-colors">${this._escape(product.name)}</div>
          ${brand}
        </div>
        ${sourceBadge}
        ${nutriscore}
        <div class="text-right shrink-0 ml-2">
          <div class="text-sm font-semibold text-brand">${product.calories} kcal</div>
          <div class="text-xs text-ink-subtle">P:${product.proteins}g · G:${product.carbs}g · L:${product.fats}g</div>
        </div>
      </button>
    `
  }

  _nutriscoreColor(grade) {
    const colors = { a: "bg-green-500", b: "bg-lime-400", c: "bg-yellow-400", d: "bg-orange-400", e: "bg-red-500" }
    return colors[grade] || "bg-surface-hover"
  }

  _escape(str) {
    const d = document.createElement("div")
    d.textContent = String(str)
    return d.innerHTML
  }

  _updateFilterBtns() {
    if (!this.hasFilterBtnTarget) return
    this.filterBtnTargets.forEach(btn => {
      const isActive = btn.dataset.foodOffSearchFilterParam === this._filter
      btn.classList.toggle("bg-brand/20",              isActive)
      btn.classList.toggle("text-brand",               isActive)
      btn.classList.toggle("border-brand/50",          isActive)
      btn.classList.toggle("bg-transparent",           !isActive)
      btn.classList.toggle("text-ink-muted",           !isActive)
      btn.classList.toggle("border-surface-border/40", !isActive)
    })
  }

  _showSpinner() {
    if (!this.hasSearchIconTarget) return
    const icon = this.searchIconTarget
    icon.classList.remove("fa-magnifying-glass", "text-ink-subtle")
    icon.classList.add("fa-circle-notch", "fa-spin", "text-brand")
  }

  _hideSpinner() {
    if (!this.hasSearchIconTarget) return
    const icon = this.searchIconTarget
    icon.classList.remove("fa-circle-notch", "fa-spin", "text-brand")
    icon.classList.add("fa-magnifying-glass", "text-ink-subtle")
  }

  _reset() {
    this._hasSearched = false
    this._allProducts = []
    this._products.clear()
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.classList.add("hidden")
    this.emptyStateTarget.classList.add("hidden")
    this.emptyFilterTarget.classList.add("hidden")
    this.typeHintTarget.classList.remove("hidden")
    this._hideSpinner()
  }
}
