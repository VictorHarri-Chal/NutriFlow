import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input", "results", "searchIcon", "clearBtn",
    "typeHint", "emptyState",
    "sourceField", "offIdField", "nutriscoreField", "novaGroupField", "ecoscoreField",
    "allergensField", "tracesField", "allergensDisplay", "tracesDisplay",
    "fiberField", "saturatedFatField", "saltField",
    "micronutrientsField",
    "badge", "ciqualBadge",
    "qualitySection",
    "nutriscoreWrapper", "nutriscoreBadge", "nutriscoreDesc",
    "novaWrapper", "novaBadge", "novaDesc",
    "ecoscoreWrapper", "ecoscoreBadge", "ecoscoreDesc"
  ]

  static NS_COLORS   = { a: "#038141", b: "#85BB2F", c: "#FECB02", d: "#EE8100", e: "#E63E11" }
  static NOVA_COLORS = { 1: "#038141", 2: "#85BB2F", 3: "#EE8100", 4: "#E63E11" }
  static ECO_COLORS  = { "a-plus": "#006400", a: "#038141", b: "#85BB2F", c: "#FECB02", d: "#EE8100", e: "#E63E11", f: "#8B1A1A" }
  static ECO_LABELS  = { "a-plus": "A+" }
  static NS_DESCS    = { a: "Excellente qualité nutritionnelle", b: "Bonne qualité nutritionnelle", c: "Qualité nutritionnelle moyenne", d: "Qualité nutritionnelle médiocre", e: "Mauvaise qualité nutritionnelle" }
  static NOVA_DESCS  = { 1: "Non transformé ou peu transformé", 2: "Ingrédient culinaire transformé", 3: "Aliment transformé", 4: "Produit ultra-transformé" }
  static ECO_DESCS   = { "a-plus": "Impact environnemental minimal", a: "Impact environnemental très faible", b: "Faible impact environnemental", c: "Impact environnemental modéré", d: "Fort impact environnemental", e: "Très fort impact environnemental", f: "Impact environnemental extrême" }
  static values = { url: String, allergensMap: Object }

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

    this._clearOffFields()
    this._fillExtendedFields(product)
    this._updateQualitySection(product)
    if (this.hasSourceFieldTarget)  this.sourceFieldTarget.value = "ciqual"
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
    if (this.hasEcoscoreFieldTarget)    this.ecoscoreFieldTarget.value    = product.ecoscore_grade || ""
    if (this.hasAllergensFieldTarget)   this.allergensFieldTarget.value   = (product.allergens  || []).join(",")
    if (this.hasTracesFieldTarget)      this.tracesFieldTarget.value      = (product.traces     || []).join(",")
    this._updateAllergenDisplays(product.allergens || [], product.traces || [])
    this._fillExtendedFields(product)

    this._updateQualitySection(product)
    if (this.hasSourceFieldTarget)  this.sourceFieldTarget.value = "off"
    if (this.hasCiqualBadgeTarget) this.ciqualBadgeTarget.classList.replace("flex", "hidden")
    if (this.hasBadgeTarget)       this.badgeTarget.classList.replace("hidden", "flex")

    document.dispatchEvent(new CustomEvent("food-off-search:import", {
      detail: { product },
      bubbles: true
    }))

    document.querySelector("[data-tab='manual']")?.click()
  }

  _clearOffFields() {
    this.offIdFieldTarget.value      = ""
    this.nutriscoreFieldTarget.value = ""
    this.novaGroupFieldTarget.value  = ""
    if (this.hasEcoscoreFieldTarget)    this.ecoscoreFieldTarget.value    = ""
    if (this.hasAllergensFieldTarget)   this.allergensFieldTarget.value   = ""
    if (this.hasTracesFieldTarget)      this.tracesFieldTarget.value      = ""
    if (this.hasSourceFieldTarget)      this.sourceFieldTarget.value      = "manual"
    this._updateAllergenDisplays([], [])
    if (this.hasQualitySectionTarget)   this.qualitySectionTarget.classList.add("hidden")
  }

  _updateQualitySection(product) {
    if (!this.hasQualitySectionTarget) return

    const ns      = product.nutriscore?.toLowerCase() || null
    const novaRaw = parseInt(product.nova_group)
    const nova    = (!isNaN(novaRaw) && novaRaw >= 1 && novaRaw <= 4) ? novaRaw : null
    const eco     = product.ecoscore_grade?.toLowerCase() || null

    if (!ns && !nova && !eco) {
      this.qualitySectionTarget.classList.add("hidden")
      return
    }
    this.qualitySectionTarget.classList.remove("hidden")

    this._setBadge(this.hasNutriscoreWrapperTarget && this.nutriscoreWrapperTarget,
                   this.hasNutriscoreBadgeTarget   && this.nutriscoreBadgeTarget,
                   ns, ns?.toUpperCase(), this.constructor.NS_COLORS)
    if (this.hasNutriscoreDescTarget) this.nutriscoreDescTarget.textContent = this.constructor.NS_DESCS[ns] || ""

    this._setBadge(this.hasNovaWrapperTarget && this.novaWrapperTarget,
                   this.hasNovaBadgeTarget   && this.novaBadgeTarget,
                   nova, nova ? String(nova) : null, this.constructor.NOVA_COLORS)
    if (this.hasNovaDescTarget) this.novaDescTarget.textContent = this.constructor.NOVA_DESCS[nova] || ""

    const ecoLetter = eco ? (this.constructor.ECO_LABELS[eco] || eco.toUpperCase()) : null
    this._setBadge(this.hasEcoscoreWrapperTarget && this.ecoscoreWrapperTarget,
                   this.hasEcoscoreBadgeTarget   && this.ecoscoreBadgeTarget,
                   eco, ecoLetter, this.constructor.ECO_COLORS)
    if (this.hasEcoscoreDescTarget) this.ecoscoreDescTarget.textContent = this.constructor.ECO_DESCS[eco] || ""
  }

  _setBadge(wrapper, badge, value, label, colorsMap) {
    if (!wrapper || !badge) return
    if (value) {
      wrapper.classList.remove("hidden")
      wrapper.classList.add("flex")
      badge.textContent = label || String(value).toUpperCase()
      badge.style.backgroundColor = colorsMap[value] || "#52525B"
    } else {
      wrapper.classList.add("hidden")
      wrapper.classList.remove("flex")
    }
  }

  _updateAllergenDisplays(allergens, traces) {
    this._setAllergenDisplay(this.hasAllergensDisplayTarget && this.allergensDisplayTarget, allergens)
    this._setAllergenDisplay(this.hasTracesDisplayTarget   && this.tracesDisplayTarget,    traces)
  }

  _setAllergenDisplay(el, values) {
    if (!el) return
    if (values.length) {
      const map = this.hasAllergensMapValue ? this.allergensMapValue : {}
      el.textContent = values.map(v => {
        const key = v.toLowerCase().replace(/-/g, "_")
        return map[key] || v
      }).join(", ")
      el.className = "text-xs font-semibold text-ink-primary text-right max-w-xs"
    } else {
      el.textContent = "—"
      el.className = "text-xs text-ink-subtle"
    }
  }

  _fillExtendedFields(product) {
    if (this.hasFiberFieldTarget)        this.fiberFieldTarget.value        = product.fiber         ?? 0
    if (this.hasSaturatedFatFieldTarget) this.saturatedFatFieldTarget.value = product.saturated_fat ?? 0
    if (this.hasSaltFieldTarget)         this.saltFieldTarget.value         = product.salt          ?? 0
    if (this.hasMicronutrientsFieldTarget) {
      this.micronutrientsFieldTarget.value = JSON.stringify(product.micronutrients || {})
    }
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
