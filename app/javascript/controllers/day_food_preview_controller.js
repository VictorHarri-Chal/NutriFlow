import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["foodId", "quantity", "calories", "proteins", "carbs", "fats", "panel"]

  connect() {
    const dataEl = document.getElementById("foods-data")
    this._foods = dataEl ? JSON.parse(dataEl.textContent) : []
    this.update()
  }

  update() {
    const foodId = parseInt(this.foodIdTarget.value) || 0
    const qty    = parseFloat(this.quantityTarget.value) || 0
    const food   = this._foods.find(f => f.id === foodId)

    if (!food || qty === 0) {
      this.panelTarget.classList.add("hidden")
      return
    }

    const scale = qty / 100
    this.panelTarget.classList.remove("hidden")
    this.caloriesTarget.textContent = Math.round(food.calories * scale)
    this.proteinsTarget.textContent = (food.proteins * scale).toFixed(1)
    this.carbsTarget.textContent    = (food.carbs    * scale).toFixed(1)
    this.fatsTarget.textContent     = (food.fats     * scale).toFixed(1)
  }
}
