import { Controller } from "@hotwired/stimulus"
import { NS_COLORS, NOVA_COLORS, ECO_COLORS, ECO_LABELS, parseQualityScores, renderAllergenChips, renderTagChips } from "off_product_renderer"

const MINERAL_KEYS = ["calcium", "iron", "magnesium", "potassium", "sodium", "zinc", "cholesterol"]
const VITAMIN_KEYS = ["vitamin_c", "vitamin_d", "vitamin_b12", "vitamin_a", "vitamin_b9", "epa", "dha"]

export default class extends Controller {
  static targets = [
    "scanStep", "productStep",
    "photo", "photoPlaceholder",
    "name", "brand", "calories",
    "proteins", "carbs", "sugarsInline", "fats", "saturatedFatRow", "saturatedFatInline",
    "fiberRow", "fiber", "saltRow", "salt",
    "mineralsSection", "mineralsList",
    "vitaminsSection", "vitaminsList",
    "qualitySection", "qualityList",
    "allergensSection", "allergensList",
    "tracesSection", "tracesList",
    "additivesSection", "additivesList",
    "labelsSection", "labelsList",
    "errorBox", "errorList",
    "successBox", "ctaBar", "addBtn", "viewExistingBtn"
  ]

  static values = {
    createUrl: String,
    allergensMap: Object,
    labelsMap: Object,
    nutrientLabels: Object,
    nsDescs: Object,
    novaDescs: Object,
    ecoDescs: Object
  }

  connect() {
    this._offId = null
    this._existingFoodId = null
    this._createdFoodId = null
  }

  handleProduct({ detail: { product, existingFood } }) {
    this.scanStepTarget.classList.add("hidden")
    this.productStepTarget.classList.remove("hidden")
    this._existingFoodId = existingFood ? existingFood.id : null

    if (!product) return

    this._offId = product.off_id
    this._renderProduct(product)
    this._toggleCta()
  }

  async addFood() {
    if (!this._offId || this.addBtnTarget.disabled) return
    this.addBtnTarget.disabled = true
    this.errorBoxTarget.classList.add("hidden")

    try {
      const res = await fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ code: this._offId })
      })
      const data = await res.json()

      if (!res.ok) {
        this.errorListTarget.innerHTML = ""
        ;(data.errors || []).forEach(message => {
          const li = document.createElement("li")
          li.textContent = message
          this.errorListTarget.appendChild(li)
        })
        this.errorBoxTarget.classList.remove("hidden")
        this.addBtnTarget.disabled = false
        return
      }

      this._createdFoodId = data.food.id
      this.ctaBarTarget.classList.add("hidden")
      this.successBoxTarget.classList.remove("hidden")
      this.successBoxTarget.scrollIntoView({ behavior: "smooth", block: "start" })
    } catch {
      this.addBtnTarget.disabled = false
    }
  }

  rescan() {
    this.successBoxTarget.classList.add("hidden")
    this.ctaBarTarget.classList.remove("hidden")
    this.productStepTarget.classList.add("hidden")
    this.scanStepTarget.classList.remove("hidden")
    this.addBtnTarget.disabled = false

    const scannerEl = this.scanStepTarget.querySelector('[data-controller~="barcode-scanner"]')
    if (scannerEl) {
      this.application.getControllerForElementAndIdentifier(scannerEl, "barcode-scanner")?.openCamera()
    }
  }

  viewFood() {
    this._openFoodInPanel(this._createdFoodId)
  }

  viewExisting() {
    this._openFoodInPanel(this._existingFoodId)
  }

  _openFoodInPanel(foodId) {
    if (!foodId) return
    document.addEventListener("turbo:load", () => {
      const frame = document.getElementById("food_show_panel")
      if (frame) frame.src = `/foods/${foodId}`
    }, { once: true })
    Turbo.visit("/foods")
  }

  _toggleCta() {
    if (this._existingFoodId) {
      this.addBtnTarget.classList.add("hidden")
      this.viewExistingBtnTarget.classList.remove("hidden")
    } else {
      this.addBtnTarget.classList.remove("hidden")
      this.viewExistingBtnTarget.classList.add("hidden")
    }
  }

  _renderProduct(product) {
    this._renderPhoto(product.image_url)
    this.nameTarget.textContent  = product.name || ""
    this.brandTarget.textContent = product.brand || ""
    this.caloriesTarget.textContent = product.calories ?? 0

    this.proteinsTarget.textContent    = `${product.proteins ?? 0} g`
    this.carbsTarget.textContent       = `${product.carbs ?? 0} g`
    this.sugarsInlineTarget.textContent = `${product.sugars ?? 0} g`
    this.fatsTarget.textContent        = `${product.fats ?? 0} g`

    this._toggleSaturatedFat(product.saturated_fat)
    this._toggleRow(this.fiberRowTarget, this.fiberTarget, product.fiber)
    this._toggleRow(this.saltRowTarget, this.saltTarget, product.salt)

    const micronutrients = product.micronutrients || {}
    this._renderNutrientGroup(this.mineralsSectionTarget, this.mineralsListTarget, micronutrients, MINERAL_KEYS)
    this._renderNutrientGroup(this.vitaminsSectionTarget, this.vitaminsListTarget, micronutrients, VITAMIN_KEYS)

    this._renderQuality(product)
    this._renderAllergens(product.allergens || [])
    this._renderTraces(product.traces || [])
    this._renderAdditives(product.additives || [])
    this._renderLabels(product.labels || [])
  }

  _renderPhoto(url) {
    if (url) {
      this.photoTarget.src = url
      this.photoTarget.classList.remove("hidden")
      this.photoPlaceholderTarget.classList.add("hidden")
    } else {
      this.photoTarget.classList.add("hidden")
      this.photoPlaceholderTarget.classList.remove("hidden")
    }
  }

  _toggleSaturatedFat(value) {
    const present = value != null && value !== 0
    this.saturatedFatRowTarget.classList.toggle("hidden", !present)
    if (present) this.saturatedFatInlineTarget.textContent = `${value} g`
  }

  _toggleRow(row, valueEl, value) {
    const present = value != null && value !== 0
    row.classList.toggle("hidden", !present)
    if (present) valueEl.textContent = `${value} g`
  }

  _renderNutrientGroup(sectionEl, listEl, micronutrients, keys) {
    const present = keys.filter(k => micronutrients[k] != null && micronutrients[k] !== 0)
    sectionEl.classList.toggle("hidden", present.length === 0)
    if (present.length === 0) return

    listEl.innerHTML = present.map(key => `
      <div class="flex items-center justify-between px-4 py-2.5">
        <span class="text-sm text-ink-muted">${this.nutrientLabelsValue[key] || key}</span>
        <span class="text-sm font-semibold text-ink-primary">${micronutrients[key]}</span>
      </div>
    `).join("")
  }

  _renderQuality(product) {
    const { ns, nova, eco } = parseQualityScores(product)

    if (!ns && !nova && !eco) {
      this.qualitySectionTarget.classList.add("hidden")
      return
    }
    this.qualitySectionTarget.classList.remove("hidden")

    const rows = []
    if (ns)   rows.push(this._scoreRowHtml(NS_COLORS[ns], ns.toUpperCase(), "Nutri-Score", this.nsDescsValue[ns]))
    if (nova) rows.push(this._scoreRowHtml(NOVA_COLORS[nova], String(nova), `NOVA ${nova}`, this.novaDescsValue[String(nova)]))
    if (eco)  rows.push(this._scoreRowHtml(ECO_COLORS[eco], ECO_LABELS[eco] || eco.toUpperCase(), "Éco-Score", this.ecoDescsValue[eco]))
    this.qualityListTarget.innerHTML = rows.join("")
  }

  _scoreRowHtml(color, badgeText, label, description) {
    return `
      <div class="bg-surface-base rounded-xl border border-surface-border/40 p-4">
        <div class="flex items-center gap-4">
          <div class="w-14 h-14 rounded-xl flex items-center justify-center shrink-0 text-white text-2xl font-black"
               style="background-color: ${color};">${badgeText}</div>
          <div>
            <div class="text-sm font-semibold text-ink-primary">${label}</div>
            <div class="text-xs text-ink-muted mt-0.5">${description || ""}</div>
          </div>
        </div>
      </div>
    `
  }

  _renderAllergens(allergens) {
    this.allergensSectionTarget.classList.toggle("hidden", allergens.length === 0)
    if (allergens.length) renderAllergenChips(this.allergensListTarget, allergens, this.allergensMapValue || {})
  }

  _renderTraces(traces) {
    this.tracesSectionTarget.classList.toggle("hidden", traces.length === 0)
    if (traces.length) renderTagChips(this.tracesListTarget, traces, this.allergensMapValue || {})
  }

  _renderAdditives(additives) {
    this.additivesSectionTarget.classList.toggle("hidden", additives.length === 0)
    if (additives.length) renderTagChips(this.additivesListTarget, additives, {})
  }

  _renderLabels(labels) {
    this.labelsSectionTarget.classList.toggle("hidden", labels.length === 0)
    if (labels.length) renderTagChips(this.labelsListTarget, labels, this.labelsMapValue || {})
  }
}
