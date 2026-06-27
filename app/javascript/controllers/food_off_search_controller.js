import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input", "results", "searchIcon", "clearBtn",
    "typeHint", "emptyState",
    "offIdField", "nutriscoreField", "novaGroupField",
    "badge", "ciqualBadge"
  ]
  static values = { url: String }

  connect() {
    this._timeout  = null
    this._products = new Map()
  }

  disconnect() {
    clearTimeout(this._timeout)
  }

  search() {
    clearTimeout(this._timeout)
    const q = this.inputTarget.value.trim()
    if (this.hasClearBtnTarget) this.clearBtnTarget.classList.toggle("hidden", q.length === 0)
    if (q.length < 2) {
      this._reset()
      return
    }
    this._timeout = setTimeout(() => this._fetch(q), 300)
  }

  clearSearch() {
    this.inputTarget.value = ""
    if (this.hasClearBtnTarget) this.clearBtnTarget.classList.add("hidden")
    this._reset()
  }

  focusInput() {
    if (this.hasInputTarget) this.inputTarget.focus()
  }

  selectProduct({ params: { index } }) {
    const product = this._products.get(String(index))
    if (!product) return

    this.offIdFieldTarget.value      = ""
    this.nutriscoreFieldTarget.value = ""
    this.novaGroupFieldTarget.value  = ""
    if (this.hasBadgeTarget)       this.badgeTarget.classList.replace("flex", "hidden")
    if (this.hasCiqualBadgeTarget) this.ciqualBadgeTarget.classList.replace("hidden", "flex")

    document.dispatchEvent(new CustomEvent("food-off-search:import", {
      detail: { product },
      bubbles: true
    }))

    document.querySelector("[data-tab='manual']")?.click()
  }

  handleBarcodeProduct({ detail: { product } }) {
    this.offIdFieldTarget.value      = product.off_id     || ""
    this.nutriscoreFieldTarget.value = product.nutriscore || ""
    this.novaGroupFieldTarget.value  = product.nova_group || ""
    if (this.hasCiqualBadgeTarget) this.ciqualBadgeTarget.classList.replace("flex", "hidden")
    if (this.hasBadgeTarget)       this.badgeTarget.classList.replace("hidden", "flex")

    document.dispatchEvent(new CustomEvent("food-off-search:import", {
      detail: { product },
      bubbles: true
    }))

    document.querySelector("[data-tab='manual']")?.click()
  }

  async _fetch(query) {
    this._showSpinner()
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
    this._products.clear()
    this.resultsTarget.innerHTML = ""

    if (products.length === 0) {
      this.resultsTarget.classList.add("hidden")
      this.typeHintTarget.classList.add("hidden")
      this.emptyStateTarget.classList.remove("hidden")
      return
    }

    this.emptyStateTarget.classList.add("hidden")
    this.typeHintTarget.classList.add("hidden")
    this.resultsTarget.classList.remove("hidden")

    products.forEach((product, i) => {
      this._products.set(String(i), product)
      const wrapper = document.createElement("div")
      wrapper.innerHTML = this._productHTML(product, i)
      this.resultsTarget.appendChild(wrapper.firstElementChild)
    })
  }

  _productHTML(product, index) {
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
          <i class="fas fa-bowl-food text-surface-border text-sm"></i>
        </div>
        <div class="flex-1 min-w-0">
          <div class="font-medium text-ink-primary text-sm truncate group-hover:text-brand transition-colors">${this._escape(product.name)}</div>
          ${brand}
        </div>
        <div class="text-right shrink-0 ml-2">
          <div class="text-sm font-semibold text-brand">${product.calories} kcal</div>
          <div class="text-xs text-ink-subtle">P:${product.proteins}g · G:${product.carbs}g · L:${product.fats}g</div>
        </div>
      </button>
    `
  }

  _escape(str) {
    const d = document.createElement("div")
    d.textContent = String(str)
    return d.innerHTML
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
    this._products.clear()
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.classList.add("hidden")
    this.emptyStateTarget.classList.add("hidden")
    this.typeHintTarget.classList.remove("hidden")
    this._hideSpinner()
  }
}
