import { Controller } from "@hotwired/stimulus"

const ACTIVITY_OFFSETS = {
  sedentary:      0,
  light_activity: 300,
  standing_job:   500,
  physical_job:   700
}

export default class extends Controller {
  static targets = ["weightInput", "hintRow", "estimatedValue", "formulaText", "goalInput"]
  static values  = { activityLabels: Object }

  connect() { this._update() }
  update()  { this._update() }

  use() {
    if (this._estimated == null) return
    this.goalInputTarget.value = this._estimated
    this.hintRowTarget.classList.add("hidden")
  }

  _update() {
    const weight   = parseFloat(this.weightInputTarget.value) || 0
    const gender   = this._checked("profile[gender]")
    const activity = this._checked("profile[job_activity_level]")

    if (weight <= 0) { this.hintRowTarget.classList.add("hidden"); return }

    const base      = weight * 33
    const gendered  = gender === "female" ? base * 0.9 : base
    const offset    = ACTIVITY_OFFSETS[activity] || 0
    const estimated = Math.round((gendered + offset) / 50) * 50
    const current   = parseInt(this.goalInputTarget.value) || 0

    this._estimated = estimated

    if (estimated !== current) {
      this.estimatedValueTarget.textContent = estimated.toLocaleString("fr-FR") + " ml/j"
      this._updateFormula(weight, gender, activity, offset)
      this.hintRowTarget.classList.remove("hidden")
    } else {
      this.hintRowTarget.classList.add("hidden")
    }
  }

  _updateFormula(weight, gender, activity, offset) {
    const parts = [`${Math.round(weight)} kg × 33 ml/kg`]
    if (gender === "female") parts.push("× 0,9 (femme)")
    if (offset > 0) {
      const label = (this.activityLabelsValue || {})[activity]
      parts.push(label ? `${label} +${offset} ml` : `+${offset} ml`)
    }
    parts.push("arrondi à 50 ml")
    this.formulaTextTarget.textContent = parts.join(" · ")
  }

  _checked(name) {
    const el = this.element.querySelector(`input[name="${name}"]:checked`)
    return el ? el.value : null
  }
}
