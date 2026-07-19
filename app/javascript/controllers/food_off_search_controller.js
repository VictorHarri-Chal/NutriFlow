import { Controller } from "@hotwired/stimulus"
import { NS_COLORS, NOVA_COLORS, ECO_COLORS, ECO_LABELS, parseQualityScores, setBadge, renderAllergenChips, renderTagChips } from "off_product_renderer"

export default class extends Controller {
  static targets = [
    "input", "results", "searchIcon", "clearBtn",
    "typeHint", "emptyState",
    "sourceField", "offIdField", "nutriscoreField", "novaGroupField", "ecoscoreField",
    "allergensField", "tracesField", "allergensDisplay", "tracesDisplay",
    "additivesField", "additivesDisplay",
    "labelsField", "labelsDisplay",
    "fiberField", "saturatedFatField", "saltField",
    "micronutrientsField",
    "badge", "ciqualBadge",
    "qualitySection",
    "nutriscoreWrapper", "nutriscoreBadge", "nutriscoreDesc",
    "novaWrapper", "novaBadge", "novaDesc",
    "ecoscoreWrapper", "ecoscoreBadge", "ecoscoreDesc",
    "additivesSection", "labelsSection",
    "allergensSection", "tracesSection",
    "advancedSection",
    "manualMicronutrientSection"
  ]

  static values = { url: String, allergensMap: Object, labelsMap: Object, nsDescs: Object, novaDescs: Object, ecoDescs: Object }

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
    this._toggleAdvancedSection(product)
    if (this.hasSourceFieldTarget)  this.sourceFieldTarget.value = "ciqual"
    if (this.hasBadgeTarget)       this.badgeTarget.classList.replace("flex", "hidden")
    if (this.hasCiqualBadgeTarget) this.ciqualBadgeTarget.classList.replace("hidden", "flex")
    if (this.hasManualMicronutrientSectionTarget) this.manualMicronutrientSectionTarget.classList.add("hidden")

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
    if (this.hasAdditivesFieldTarget)   this.additivesFieldTarget.value   = (product.additives  || []).join(",")
    if (this.hasLabelsFieldTarget)      this.labelsFieldTarget.value      = (product.labels     || []).join(",")
    this._updateAllergenDisplays(product.allergens || [], product.traces || [])
    this._toggleTagSection(this.hasAllergensSectionTarget && this.allergensSectionTarget, product.allergens || [])
    this._toggleTagSection(this.hasTracesSectionTarget    && this.tracesSectionTarget,    product.traces    || [])
    this._updateTagDisplay(this.hasAdditivesDisplayTarget && this.additivesDisplayTarget, product.additives || [], {})
    this._updateTagDisplay(this.hasLabelsDisplayTarget    && this.labelsDisplayTarget,    product.labels    || [], this.hasLabelsMapValue ? this.labelsMapValue : {})
    this._toggleTagSection(this.hasAdditivesSectionTarget && this.additivesSectionTarget, product.additives || [])
    this._toggleTagSection(this.hasLabelsSectionTarget    && this.labelsSectionTarget,    product.labels    || [])
    this._fillExtendedFields(product)

    this._updateQualitySection(product)
    this._toggleAdvancedSection(product)
    if (this.hasSourceFieldTarget)  this.sourceFieldTarget.value = "off"
    if (this.hasCiqualBadgeTarget) this.ciqualBadgeTarget.classList.replace("flex", "hidden")
    if (this.hasBadgeTarget)       this.badgeTarget.classList.replace("hidden", "flex")
    if (this.hasManualMicronutrientSectionTarget) this.manualMicronutrientSectionTarget.classList.add("hidden")

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
    if (this.hasAdditivesFieldTarget)   this.additivesFieldTarget.value   = ""
    if (this.hasLabelsFieldTarget)      this.labelsFieldTarget.value      = ""
    if (this.hasSourceFieldTarget)      this.sourceFieldTarget.value      = "manual"
    this._updateAllergenDisplays([], [])
    this._toggleTagSection(this.hasAllergensSectionTarget && this.allergensSectionTarget, [])
    this._toggleTagSection(this.hasTracesSectionTarget    && this.tracesSectionTarget,    [])
    this._updateTagDisplay(this.hasAdditivesDisplayTarget && this.additivesDisplayTarget, [], {})
    this._updateTagDisplay(this.hasLabelsDisplayTarget    && this.labelsDisplayTarget,    [], {})
    this._toggleTagSection(this.hasAdditivesSectionTarget && this.additivesSectionTarget, [])
    this._toggleTagSection(this.hasLabelsSectionTarget    && this.labelsSectionTarget,    [])
    if (this.hasQualitySectionTarget)   this.qualitySectionTarget.classList.add("hidden")
    if (this.hasAdvancedSectionTarget)  this.advancedSectionTarget.classList.add("hidden")
    if (this.hasManualMicronutrientSectionTarget) this.manualMicronutrientSectionTarget.classList.remove("hidden")
  }

  _updateQualitySection(product) {
    if (!this.hasQualitySectionTarget) return

    const { ns, nova, eco } = parseQualityScores(product)

    if (!ns && !nova && !eco) {
      this.qualitySectionTarget.classList.add("hidden")
      return
    }
    this.qualitySectionTarget.classList.remove("hidden")

    setBadge(this.hasNutriscoreWrapperTarget && this.nutriscoreWrapperTarget,
             this.hasNutriscoreBadgeTarget   && this.nutriscoreBadgeTarget,
             ns, ns?.toUpperCase(), NS_COLORS)
    if (this.hasNutriscoreDescTarget) this.nutriscoreDescTarget.textContent = this.nsDescsValue[ns] || ""

    setBadge(this.hasNovaWrapperTarget && this.novaWrapperTarget,
             this.hasNovaBadgeTarget   && this.novaBadgeTarget,
             nova, nova ? String(nova) : null, NOVA_COLORS)
    if (this.hasNovaDescTarget) this.novaDescTarget.textContent = this.novaDescsValue[String(nova)] || ""

    const ecoLetter = eco ? (ECO_LABELS[eco] || eco.toUpperCase()) : null
    setBadge(this.hasEcoscoreWrapperTarget && this.ecoscoreWrapperTarget,
             this.hasEcoscoreBadgeTarget   && this.ecoscoreBadgeTarget,
             eco, ecoLetter, ECO_COLORS)
    if (this.hasEcoscoreDescTarget) this.ecoscoreDescTarget.textContent = this.ecoDescsValue[eco] || ""
  }

  _updateAllergenDisplays(allergens, traces) {
    const map = this.hasAllergensMapValue ? this.allergensMapValue : {}
    if (this.hasAllergensDisplayTarget) renderAllergenChips(this.allergensDisplayTarget, allergens, map)
    this._updateTagDisplay(this.hasTracesDisplayTarget && this.tracesDisplayTarget, traces, map)
  }

  _updateTagDisplay(el, values, map) {
    renderTagChips(el, values, map)
  }

  _toggleTagSection(el, values) {
    if (!el) return
    el.classList.toggle("hidden", values.length === 0)
  }

  _toggleAdvancedSection(product) {
    if (!this.hasAdvancedSectionTarget) return
    const hasAllergens     = (product.allergens  || []).length > 0
    const hasTraces        = (product.traces     || []).length > 0
    const hasAdditives     = (product.additives  || []).length > 0
    const hasLabels        = (product.labels     || []).length > 0
    const hasMicronutrients = product.micronutrients &&
      Object.values(product.micronutrients).some(v => v != null && v !== 0)
    const hasAny = hasAllergens || hasTraces || hasAdditives || hasLabels || hasMicronutrients
    this.advancedSectionTarget.classList.toggle("hidden", !hasAny)
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
