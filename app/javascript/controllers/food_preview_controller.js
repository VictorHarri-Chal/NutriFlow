import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "calories", "proteins", "carbs", "fats", "sugars",
    "nameField", "brandField",
    "micronutrientDisplay", "micronutrientsSection"
  ]

  fillFromOff({ detail: { product } }) {
    if (this.hasNameFieldTarget)  this.nameFieldTarget.value  = product.name  || ""
    if (this.hasBrandFieldTarget) this.brandFieldTarget.value = product.brand || ""

    if (this.hasCaloriesTarget) this.caloriesTarget.value = product.calories ?? 0
    if (this.hasProteinsTarget) this.proteinsTarget.value = product.proteins ?? 0
    if (this.hasCarbsTarget)    this.carbsTarget.value    = product.carbs    ?? 0
    if (this.hasFatsTarget)     this.fatsTarget.value     = product.fats     ?? 0
    if (this.hasSugarsTarget)   this.sugarsTarget.value   = product.sugars   ?? 0

    if (this.hasMicronutrientDisplayTarget && product.micronutrients) {
      let anyMicronutrient = false
      this.micronutrientDisplayTargets.forEach(el => {
        const key = el.dataset.nutrient
        const val = product.micronutrients[key]
        const row = el.closest("[data-nutrient-row]")
        if (val != null && val !== 0) {
          anyMicronutrient = true
          if (row) row.classList.remove("hidden")
          el.textContent = `${val} ${el.dataset.unit}`
          el.className = "text-xs font-semibold text-ink-primary"
        } else {
          if (row) row.classList.add("hidden")
          el.textContent = "—"
          el.className = "text-xs text-ink-subtle"
        }
      })
      if (this.hasMicronutrientsSectionTarget) {
        this.micronutrientsSectionTarget.classList.toggle("hidden", !anyMicronutrient)
      }
    }
  }
}
