import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["foodId", "quantity", "calories", "proteins", "carbs", "fats", "panel"]
  static values = { snapshot: Object }

  connect() {
    const dataEl = document.getElementById("foods-data")
    this._foods = dataEl ? JSON.parse(dataEl.textContent) : []
    this.update()
  }

  update() {
    const foodId = parseInt(this.foodIdTarget.value) || 0
    const qty    = parseFloat(this.quantityTarget.value) || 0
    // Aliment vivant dans la banque, sinon repli sur le snapshot figé (log dont
    // l'aliment a été supprimé) — l'aperçu reste juste dans les deux cas.
    const source = this._foods.find(f => f.id === foodId) || this._snapshotSource()

    if (!source || qty === 0) {
      this.panelTarget.classList.add("hidden")
      return
    }

    const scale = qty / 100
    this.panelTarget.classList.remove("hidden")
    this.caloriesTarget.textContent = Math.round((source.calories || 0) * scale)
    this.proteinsTarget.textContent = ((source.proteins || 0) * scale).toFixed(1)
    this.carbsTarget.textContent    = ((source.carbs    || 0) * scale).toFixed(1)
    this.fatsTarget.textContent     = ((source.fats     || 0) * scale).toFixed(1)
  }

  _snapshotSource() {
    const s = this.snapshotValue
    return (s && Object.keys(s).length > 0) ? s : null
  }
}
