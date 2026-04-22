import { Controller } from "@hotwired/stimulus"

// Live macro preview for the "Ajouter un plat" form.
// Scaling formula: qty / total_weight (recipes store absolute totals, not per-100g)
export default class extends Controller {
  static targets = ["recipeId", "quantity", "useRecipeQty", "calories", "proteins", "carbs", "fats", "panel"]

  connect() {
    const dataEl = document.getElementById("recipes-data")
    this._recipes = dataEl ? JSON.parse(dataEl.textContent) : []
    this.update()
  }

  update() {
    const recipeId = parseInt(this.recipeIdTarget.value) || 0
    const recipe   = this._recipes.find(r => r.id === recipeId)

    if (!recipe || recipe.totalWeight <= 0) {
      this.panelTarget.classList.add("hidden")
      return
    }

    const useTotal = this.hasUseRecipeQtyTarget && this.useRecipeQtyTarget.checked
    const qty      = useTotal ? recipe.totalWeight : (parseFloat(this.quantityTarget.value) || 0)

    if (qty <= 0) {
      this.panelTarget.classList.add("hidden")
      return
    }

    const scale = qty / recipe.totalWeight
    this.panelTarget.classList.remove("hidden")
    this.caloriesTarget.textContent = Math.round(recipe.calories * scale)
    this.proteinsTarget.textContent = (recipe.proteins * scale).toFixed(1)
    this.carbsTarget.textContent    = (recipe.carbs    * scale).toFixed(1)
    this.fatsTarget.textContent     = (recipe.fats     * scale).toFixed(1)
  }
}
