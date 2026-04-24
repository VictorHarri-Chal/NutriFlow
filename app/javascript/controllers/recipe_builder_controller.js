import { Controller } from "@hotwired/stimulus"

const UNIT_GRAM_MULTIPLIERS = {
  g:  1,
  kg: 1000,
  mL: 1,
  L:  1000
}

export default class extends Controller {
  static targets = [
    "emptyPanel", "statsPanel",
    "totalCalories", "totalProteins", "totalCarbs", "totalFats", "totalSugars", "totalWeight",
    "ingredientList", "ingredientCount",
    "instructionsPanel", "instructionsChevron"
  ]

  connect() {
    const dataEl = document.getElementById("foods-data")
    this.foodsMap = {}
    if (dataEl) {
      JSON.parse(dataEl.textContent).forEach(f => { this.foodsMap[f.id] = f })
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

    items.forEach(({ food, quantity, unit }) => {
      const grams = quantity * (UNIT_GRAM_MULTIPLIERS[unit] || 1)
      const factor = grams / 100
      calories += food.calories * factor
      proteins += food.proteins * factor
      carbs    += food.carbs    * factor
      fats     += food.fats     * factor
      sugars   += (food.sugars || 0) * factor
      weight   += grams
    })

    this.totalCaloriesTarget.textContent = Math.round(calories)
    this.totalProteinsTarget.textContent = proteins.toFixed(1)
    this.totalCarbsTarget.textContent    = carbs.toFixed(1)
    this.totalFatsTarget.textContent     = fats.toFixed(1)
    if (this.hasTotalSugarsTarget) this.totalSugarsTarget.textContent = sugars.toFixed(1)
    this.totalWeightTarget.textContent   = Math.round(weight)
    this.ingredientCountTarget.textContent = items.length

    // Per-ingredient breakdown
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

  toggleInstructions() {
    const panel = this.instructionsPanelTarget
    const chevron = this.instructionsChevronTarget
    const isHidden = panel.classList.contains("hidden")
    panel.classList.toggle("hidden", !isHidden)
    chevron.classList.toggle("rotate-180", isHidden)
  }

  // ── Private ─────────────────────────────────────────────────────

  _getValidItems() {
    const items = []
    this.element.querySelectorAll("[data-nested-form-target='item']").forEach(row => {
      if (row.style.display === "none") return
      const hiddenId    = row.querySelector("[data-food-combobox-target='hiddenId']")
      const quantityInput = row.querySelector("input[name*='[quantity]']")
      const unitInput   = row.querySelector("input[name*='[unit]']")
      if (!hiddenId || !quantityInput) return
      const foodId   = parseInt(hiddenId.value)
      const quantity = parseFloat(quantityInput.value)
      const unit     = unitInput ? unitInput.value || "g" : "g"
      const food     = this.foodsMap[foodId]
      if (food && quantity > 0) items.push({ food, quantity, unit })
    })
    return items
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
