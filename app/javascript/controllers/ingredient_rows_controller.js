import { Controller } from "@hotwired/stimulus"
import { UNIT_GRAM_MULTIPLIERS } from "unit_conversions"

// Guards a recipe/day-recipe ingredient list (rendered via shared/_ingredient_fields)
// right before its enclosing form submits, or before a customize-modal "Valider"
// confirms — mirrors the RecipeItem/DayRecipeItem server validations (food_id
// presence, quantity >= 1) so the user sees the problem without a round trip.
export default class extends Controller {
  static targets = ["row", "errorBox"]
  static values = { minQuantity: { type: Number, default: 1 } }

  guardSubmit(event) {
    if (!this._validate()) event.preventDefault()
  }

  guardConfirm(event) {
    if (!this._validate()) {
      event.preventDefault()
      event.stopImmediatePropagation()
    }
  }

  _validate() {
    let missingFood = false
    let badQuantity = false

    this._visibleRows.forEach(row => {
      const foodNameField = row.querySelector('[data-role="food-name"]')
      const foodIdField = row.querySelector('[data-role="food-id"]')
      const quantityField = row.querySelector('[data-role="quantity"]')
      const unitField = row.querySelector('[data-role="unit-hidden"]')

      const foodOk = !!foodIdField && parseInt(foodIdField.value, 10) > 0
      // `quantity` is a raw number in whatever unit is selected (g/kg/mL/L) — compare
      // its gram-equivalent to the minimum, not the raw value, so "0.5 kg" (= 500 g)
      // isn't wrongly rejected. Mirrors RecipeItem/DayRecipeItem#grams_equivalent,
      // which is itself rounded to 1 decimal — round here too, or a value like
      // "0.95 g" (server-side: rounds up to 1.0, valid) gets wrongly blocked client-side.
      const multiplier = UNIT_GRAM_MULTIPLIERS[unitField?.value] ?? 1.0
      const rawQuantity = quantityField ? parseFloat(quantityField.value.replace(",", ".")) : NaN
      const gramsEquivalent = Math.round(rawQuantity * multiplier * 10) / 10
      const quantityOk = gramsEquivalent >= this.minQuantityValue

      foodNameField?.classList.toggle("border-status-danger", !foodOk)
      foodNameField?.classList.toggle("focus:ring-status-danger/50", !foodOk)
      foodNameField?.classList.toggle("focus:border-status-danger", !foodOk)
      quantityField?.classList.toggle("border-status-danger", !quantityOk)
      quantityField?.classList.toggle("focus:ring-status-danger/50", !quantityOk)
      quantityField?.classList.toggle("focus:border-status-danger", !quantityOk)

      if (!foodOk) missingFood = true
      if (!quantityOk) badQuantity = true
    })

    const messages = []
    if (missingFood) messages.push(this.errorBoxTarget.dataset.missingFoodMessage)
    if (badQuantity) messages.push(this.errorBoxTarget.dataset.badQuantityMessage)
    this._renderErrors(messages)

    return messages.length === 0
  }

  _renderErrors(messages) {
    if (!this.hasErrorBoxTarget) return
    this.errorBoxTarget.querySelector("ul").innerHTML = messages.map(m => `<li>${m}</li>`).join("")
    this.errorBoxTarget.classList.toggle("hidden", messages.length === 0)
  }

  get _visibleRows() {
    return this.rowTargets.filter(row => row.style.display !== "none")
  }
}
