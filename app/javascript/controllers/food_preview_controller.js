import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "calories", "proteins", "carbs", "fats", "sugars",
    "previewCalories", "previewProteins", "previewCarbs", "previewFats", "previewSugars",
    "emptyPanel", "statsPanel", "barProteins", "barCarbs", "barFats",
    "nameField", "brandField",
    "micronutrientDisplay"
  ]

  connect() {
    this.update()
  }

  fillFromOff({ detail: { product } }) {
    if (this.hasNameFieldTarget)  this.nameFieldTarget.value  = product.name  || ""
    if (this.hasBrandFieldTarget) this.brandFieldTarget.value = product.brand || ""

    if (this.hasCaloriesTarget) this.caloriesTarget.value = product.calories ?? 0
    if (this.hasProteinsTarget) this.proteinsTarget.value = product.proteins ?? 0
    if (this.hasCarbsTarget)    this.carbsTarget.value    = product.carbs    ?? 0
    if (this.hasFatsTarget)     this.fatsTarget.value     = product.fats     ?? 0
    if (this.hasSugarsTarget)   this.sugarsTarget.value   = product.sugars   ?? 0

    if (this.hasMicronutrientDisplayTarget && product.micronutrients) {
      this.micronutrientDisplayTargets.forEach(el => {
        const key = el.dataset.nutrient
        const val = product.micronutrients[key]
        if (val != null && val !== 0) {
          el.textContent = `${val} ${el.dataset.unit}`
          el.className = "text-xs font-semibold text-ink-primary"
        } else {
          el.textContent = "—"
          el.className = "text-xs text-ink-subtle"
        }
      })
    }

    this.update()
  }

  update() {
    if (!this.hasCaloriesTarget) return

    const cal  = parseFloat(this.caloriesTarget.value)  || 0
    const prot = parseFloat(this.proteinsTarget.value)  || 0
    const carb = parseFloat(this.carbsTarget.value)     || 0
    const fat  = parseFloat(this.fatsTarget.value)      || 0
    const sug  = parseFloat(this.sugarsTarget.value)    || 0

    if (!this.hasEmptyPanelTarget) return

    const isEmpty = cal === 0 && prot === 0 && carb === 0 && fat === 0

    if (isEmpty) {
      this.emptyPanelTarget.classList.remove("hidden")
      this.statsPanelTarget.classList.add("hidden")
      return
    }

    this.emptyPanelTarget.classList.add("hidden")
    this.statsPanelTarget.classList.remove("hidden")

    this.previewCaloriesTarget.textContent = Math.round(cal)
    this.previewProteinsTarget.textContent = prot.toFixed(1)
    this.previewCarbsTarget.textContent    = carb.toFixed(1)
    this.previewFatsTarget.textContent     = fat.toFixed(1)
    this.previewSugarsTarget.textContent   = sug.toFixed(1)

    const total = prot + carb + fat
    if (total > 0) {
      this.barProteinsTarget.style.width = `${(prot / total * 100).toFixed(1)}%`
      this.barCarbsTarget.style.width    = `${(carb / total * 100).toFixed(1)}%`
      this.barFatsTarget.style.width     = `${(fat  / total * 100).toFixed(1)}%`
    } else {
      this.barProteinsTarget.style.width = "0%"
      this.barCarbsTarget.style.width    = "0%"
      this.barFatsTarget.style.width     = "0%"
    }
  }
}
