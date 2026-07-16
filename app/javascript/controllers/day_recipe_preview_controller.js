import { Controller } from "@hotwired/stimulus"
import { UNIT_GRAM_MULTIPLIERS } from "unit_conversions"

// Live macro preview for the "Ajouter un plat" form.
// Non-customized: scaling formula qty / total_weight (recipes store absolute totals, not per-100g).
// Customized: sum of the individually edited day_recipe_items rows (each scaled from its own food's per-100g values).

export default class extends Controller {
  static targets = ["recipeId", "quantity", "useRecipeQty", "itemsContainer", "calories", "proteins", "carbs", "fats", "panel"]

  connect() {
    const recipesEl = document.getElementById("recipes-data")
    this._recipes = recipesEl ? JSON.parse(recipesEl.textContent) : []

    const foodsEl = document.getElementById("foods-data")
    const foods = foodsEl ? JSON.parse(foodsEl.textContent) : []
    this._foodsById = Object.fromEntries(foods.map(food => [food.id, food]))

    this.update()
  }

  update() {
    const useTotal = this.hasUseRecipeQtyTarget && this.useRecipeQtyTarget.checked
    // Never force-disable while customized: day-recipe-customize already makes
    // it readonly, and disabling it here would drop it from the submitted
    // params, losing the frozen base quantity.
    if (!this._isCustomized) this.quantityTarget.disabled = useTotal

    if (this._isCustomized) {
      this._updateFromCustomizedItems()
    } else {
      this._updateFromRecipeScale(useTotal)
    }
  }

  // The modal seeds itemsContainer as soon as it's opened, before the user
  // confirms — so the live preview follows what's actually in the DOM, not
  // the persisted `customized` flag (which only flips on confirm).
  get _isCustomized() {
    if (!this.hasItemsContainerTarget) return false
    return Array.from(this.itemsContainerTarget.querySelectorAll('[data-nested-form-target="item"]'))
      .some(row => row.style.display !== "none")
  }

  _updateFromRecipeScale(useTotal) {
    const recipeId = parseInt(this.recipeIdTarget.value) || 0
    const recipe   = this._recipes.find(r => r.id === recipeId)

    if (!recipe || recipe.totalWeight <= 0) {
      this.panelTarget.classList.add("hidden")
      return
    }

    const qty = useTotal ? recipe.totalWeight : (parseFloat(this.quantityTarget.value) || 0)

    if (qty <= 0) {
      this.panelTarget.classList.add("hidden")
      return
    }

    const scale = qty / recipe.totalWeight
    this._render(recipe.calories * scale, recipe.proteins * scale, recipe.carbs * scale, recipe.fats * scale)
  }

  _updateFromCustomizedItems() {
    if (!this.hasItemsContainerTarget) {
      this.panelTarget.classList.add("hidden")
      return
    }

    let calories = 0, proteins = 0, carbs = 0, fats = 0

    this.itemsContainerTarget.querySelectorAll('[data-nested-form-target="item"]').forEach(row => {
      if (row.style.display === "none") return
      const destroyField = row.querySelector('[data-nested-form-target="destroyField"]')
      if (destroyField && destroyField.value === "1") return

      const foodId   = parseInt(row.querySelector('[data-role="food-id"]')?.value) || 0
      const quantity = parseFloat(row.querySelector('[data-role="quantity"]')?.value) || 0
      const unit     = row.querySelector('[data-role="unit-hidden"]')?.value || "g"
      const food     = this._foodsById[foodId]
      if (!food || quantity <= 0) return

      const gramFactor = (quantity * (UNIT_GRAM_MULTIPLIERS[unit] || 1.0)) / 100.0
      calories += food.calories * gramFactor
      proteins += food.proteins * gramFactor
      carbs    += food.carbs    * gramFactor
      fats     += food.fats     * gramFactor
    })

    this._render(calories, proteins, carbs, fats)
  }

  _render(calories, proteins, carbs, fats) {
    this.panelTarget.classList.remove("hidden")
    this.caloriesTargets.forEach(el => { el.textContent = Math.round(calories) })
    this.proteinsTargets.forEach(el => { el.textContent = proteins.toFixed(1) })
    this.carbsTargets.forEach(el   => { el.textContent = carbs.toFixed(1) })
    this.fatsTargets.forEach(el    => { el.textContent = fats.toFixed(1) })
  }
}
