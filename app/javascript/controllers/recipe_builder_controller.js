import { Controller } from "@hotwired/stimulus"
import { UNIT_GRAM_MULTIPLIERS } from "unit_conversions"

const MICRONUTRIENT_ORDER = [
  "calcium", "iron", "magnesium", "potassium", "sodium", "zinc", "cholesterol",
  "vitamin_c", "vitamin_d", "vitamin_b12", "vitamin_a", "vitamin_b9", "epa", "dha"
]

export default class extends Controller {
  static targets = [
    "emptyPanel", "statsPanel",
    "totalCalories", "totalProteins", "totalCarbs", "totalFats", "totalSugars", "totalWeight",
    "totalFiber", "totalSaturatedFat", "totalSalt",
    "micronutrientsSection", "micronutrientsList",
    "allergensSection", "allergensList",
    "ingredientList", "ingredientCount"
  ]

  connect() {
    const dataEl = document.getElementById("foods-data")
    this.foodsMap = {}
    if (dataEl) {
      JSON.parse(dataEl.textContent).forEach(f => { this.foodsMap[f.id] = f })
    }

    const labelsEl = document.getElementById("recipe-labels-data")
    this.micronutrientLabels = {}
    this.micronutrientUnits  = {}
    this.allergenLabels      = {}
    if (labelsEl) {
      const labels = JSON.parse(labelsEl.textContent)
      this.micronutrientLabels = labels.micronutrients      || {}
      this.micronutrientUnits  = labels.micronutrient_units || {}
      this.allergenLabels      = labels.allergens           || {}
    }

    this.update()
  }

  update() {
    const items = this._getValidItems()

    if (items.length === 0) {
      this._showEmpty()
      return
    }

    let calories = 0, proteins = 0, carbs = 0, fats = 0, sugars = 0, weight = 0
    let fiber = 0, saturatedFat = 0, salt = 0
    const micronutrients = {}
    const allergenSet = new Set()

    items.forEach(({ food, quantity, unit }) => {
      const grams  = quantity * (UNIT_GRAM_MULTIPLIERS[unit] || 1)
      const factor = grams / 100
      calories     += food.calories * factor
      proteins     += food.proteins * factor
      carbs        += food.carbs    * factor
      fats         += food.fats     * factor
      sugars       += (food.sugars || 0) * factor
      weight       += grams
      fiber        += (food.fiber         || 0) * factor
      saturatedFat += (food.saturated_fat || 0) * factor
      salt         += (food.salt          || 0) * factor

      if (food.micronutrients) {
        Object.entries(food.micronutrients).forEach(([key, value]) => {
          if (value) micronutrients[key] = (micronutrients[key] || 0) + value * factor
        })
      }

      if (food.allergens) food.allergens.forEach(a => allergenSet.add(a))
    })

    if (this.hasTotalCaloriesTarget)     this.totalCaloriesTarget.textContent     = Math.round(calories)
    if (this.hasTotalProteinsTarget)     this.totalProteinsTarget.textContent     = proteins.toFixed(1)
    if (this.hasTotalCarbsTarget)        this.totalCarbsTarget.textContent        = carbs.toFixed(1)
    if (this.hasTotalFatsTarget)         this.totalFatsTarget.textContent         = fats.toFixed(1)
    if (this.hasTotalSugarsTarget)       this.totalSugarsTarget.textContent       = sugars.toFixed(1)
    if (this.hasTotalFiberTarget)        this.totalFiberTarget.textContent        = fiber.toFixed(1)
    if (this.hasTotalSaturatedFatTarget) this.totalSaturatedFatTarget.textContent = saturatedFat.toFixed(1)
    if (this.hasTotalSaltTarget)         this.totalSaltTarget.textContent         = salt.toFixed(1)
    if (this.hasTotalWeightTarget)       this.totalWeightTarget.textContent       = Math.round(weight)
    if (this.hasIngredientCountTarget)   this.ingredientCountTarget.textContent   = items.length

    this._updateMicronutrients(micronutrients)
    this._updateAllergens(allergenSet)

    // Per-ingredient breakdown
    if (!this.hasIngredientListTarget) return
    this.ingredientListTarget.innerHTML = items.map(({ food, quantity, unit }) => {
      const grams = quantity * (UNIT_GRAM_MULTIPLIERS[unit] || 1)
      const kcal  = Math.round(food.calories * grams / 100)
      return `
        <div class="flex items-center justify-between gap-2 text-xs py-1.5 border-b border-surface-border/30 last:border-0">
          <span class="text-ink-muted truncate">${food.name}</span>
          <span class="text-ink-subtle shrink-0">${quantity}${unit} · <span class="text-brand font-medium">${kcal} kcal</span></span>
        </div>
      `
    }).join("")

    this._showStats()
  }

  // ── Private ─────────────────────────────────────────────────────

  _getValidItems() {
    const items = []
    this.element.querySelectorAll("[data-nested-form-target='item']").forEach(row => {
      if (row.style.display === "none") return
      const hiddenId      = row.querySelector("[data-food-combobox-target='hiddenId']")
      const quantityInput = row.querySelector("input[name*='[quantity]']")
      const unitInput     = row.querySelector("input[name*='[unit]']")
      if (!hiddenId || !quantityInput) return
      const foodId   = parseInt(hiddenId.value)
      const quantity = parseFloat(quantityInput.value)
      const unit     = unitInput ? unitInput.value || "g" : "g"
      const food     = this.foodsMap[foodId]
      if (food && quantity > 0) items.push({ food, quantity, unit })
    })
    return items
  }

  _updateMicronutrients(mn) {
    const ordered = MICRONUTRIENT_ORDER
      .map(key => ({ key, value: mn[key] }))
      .filter(({ value }) => value && value > 0)

    if (this.hasMicronutrientsSectionTarget) {
      this.micronutrientsSectionTarget.classList.toggle("hidden", ordered.length === 0)
    }

    if (this.hasMicronutrientsListTarget && ordered.length > 0) {
      this.micronutrientsListTarget.innerHTML = ordered.map(({ key, value }) => {
        const label = this.micronutrientLabels[key] || key
        const unit  = this.micronutrientUnits[key]  || ""
        return `
          <div class="flex items-center justify-between py-0.5 border-b border-surface-border/20 last:border-0">
            <span class="text-xs text-ink-muted">${label}</span>
            <span class="text-xs font-semibold text-ink-primary tabular-nums">${value.toFixed(1)} ${unit}</span>
          </div>
        `
      }).join("")
    }
  }

  _updateAllergens(allergenSet) {
    const allergens = Array.from(allergenSet)

    if (this.hasAllergensSectionTarget) {
      this.allergensSectionTarget.classList.toggle("hidden", allergens.length === 0)
    }

    if (this.hasAllergensListTarget && allergens.length > 0) {
      this.allergensListTarget.innerHTML = allergens.map(a => {
        const label = this.allergenLabels[a] || a
        return `<span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium bg-status-warning/10 text-status-warning border border-status-warning/30">${label}</span>`
      }).join(" ")
    }
  }

  _showEmpty() {
    if (this.hasEmptyPanelTarget) this.emptyPanelTarget.classList.remove("hidden")
    if (this.hasStatsPanelTarget) this.statsPanelTarget.classList.add("hidden")
  }

  _showStats() {
    if (this.hasEmptyPanelTarget) this.emptyPanelTarget.classList.add("hidden")
    if (this.hasStatsPanelTarget) this.statsPanelTarget.classList.remove("hidden")
  }
}
