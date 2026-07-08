import { Controller } from "@hotwired/stimulus"

const RECOMMENDED_LOSS_MAX = -1.0 // more negative than this = too aggressive
const RECOMMENDED_GAIN_MAX = 0.5  // more positive than this = too aggressive

const ACTIVE_CARD_CLASS   = "flex flex-col items-center gap-3 p-5 rounded-xl border text-center transition-colors bg-brand/10 border-brand text-brand"
const INACTIVE_CARD_CLASS = "flex flex-col items-center gap-3 p-5 rounded-xl border text-center transition-colors bg-surface-hover border-surface-border/50 text-ink-muted opacity-50"

export default class extends Controller {
  static targets = [
    "content", "placeholder", "goalCard",
    "rateRow", "rateInput", "rateDisplay", "rateMinLabel", "rateMaxLabel",
    "warningLoss", "warningGain", "estimateRow", "estimateValue",
    "weightInput", "heightInput", "ageInput", "goalWeightInput"
  ]
  static values = {
    defaultLossRate: Number,
    defaultGainRate: Number,
    unitLabel: String,
    rateMin: Number,
    rateMax: Number,
    estimateTemplate: String,
    goalWeightTouched: Boolean
  }

  connect() {
    this._goalWeightTouched = this.goalWeightTouchedValue
    this.update()
  }

  // The user explicitly editing goal weight themselves stops the
  // weight->goalWeight mirroring below — their choice always wins.
  goalWeightChanged() {
    this._goalWeightTouched = true
  }

  update() {
    if (!this._toggleSection()) return

    this._prefillGoalWeight()

    const goalChanged = this._applyImpliedGoal()
    if (goalChanged) this._syncRateRow(this._currentGoal)

    const rate = parseFloat(this.rateInputTarget.value) || 0
    this._updateDisplay(rate)
    this._updateWarning(rate)
    this._updateEstimate(rate)
  }

  // The whole goal section needs weight, height and date of birth (same
  // requirement as BMR) — without all three, goal weight, the cards, the
  // rate row and its personalised defaults have nothing sound to compute
  // from. Rather than let them show a half-broken state (0 as a phantom
  // weight, a slider popping in and out), show a calm placeholder instead.
  // Returns whether the section is currently usable.
  _toggleSection() {
    const ready =
      (parseFloat(this.weightInputTarget.value) || 0) > 0 &&
      (parseFloat(this.heightInputTarget.value) || 0) > 0 &&
      this.ageInputTarget.value !== ""

    this.contentTarget.classList.toggle("hidden", !ready)
    this.placeholderTarget.classList.toggle("hidden", ready)
    return ready
  }

  // Mirrors weight into goal weight until the user picks their own value —
  // this only ever applies before goal weight has been touched, so it
  // never overwrites an intentional choice.
  _prefillGoalWeight() {
    if (this._goalWeightTouched) return

    const weight = parseFloat(this.weightInputTarget.value) || 0
    if (weight > 0) this.goalWeightInputTarget.value = weight
  }

  // The goal is entirely derived from comparing weight to goal weight
  // (lower target = weight_loss, higher = muscle_gain, equal = maintenance)
  // — there is no manual selection. Returns true if the derived goal
  // changed, so callers can re-sync the rate row (bounds/visibility/default).
  _applyImpliedGoal() {
    const weight     = parseFloat(this.weightInputTarget.value) || 0
    const goalWeight = parseFloat(this.goalWeightInputTarget.value) || 0

    let implied = null
    if (weight > 0 && goalWeight > 0) {
      if (goalWeight < weight) implied = "weight_loss"
      else if (goalWeight > weight) implied = "muscle_gain"
      else implied = "maintenance"
    }

    const changed = implied !== null && implied !== this._currentGoal
    if (implied !== null) this._currentGoal = implied

    this.goalCardTargets.forEach(card => {
      card.className = implied !== null && card.dataset.goalValue === implied
        ? ACTIVE_CARD_CLASS
        : INACTIVE_CARD_CLASS
    })

    return changed
  }

  _syncRateRow(goal) {
    if (goal === "maintenance" || !goal) {
      this.rateRowTarget.classList.add("hidden")
      return
    }

    this.rateRowTarget.classList.remove("hidden")
    this._applyBoundsForGoal(goal)

    const current = parseFloat(this.rateInputTarget.value)
    if (!current) {
      this.rateInputTarget.value = goal === "weight_loss" ? this.defaultLossRateValue : this.defaultGainRateValue
    }
  }

  _applyBoundsForGoal(goal) {
    const min = goal === "muscle_gain" ? 0 : this.rateMinValue
    const max = goal === "weight_loss" ? 0 : this.rateMaxValue

    this.rateInputTarget.min = min
    this.rateInputTarget.max = max
    this.rateMinLabelTarget.textContent = min
    this.rateMaxLabelTarget.textContent = max
  }

  _updateDisplay(rate) {
    const sign = rate > 0 ? "+" : ""
    this.rateDisplayTarget.textContent = `${sign}${rate.toFixed(2)} ${this.unitLabelValue}`
  }

  _updateWarning(rate) {
    this.warningLossTarget.classList.toggle("hidden", rate >= RECOMMENDED_LOSS_MAX)
    this.warningGainTarget.classList.toggle("hidden", rate <= RECOMMENDED_GAIN_MAX)
  }

  // Note: goal is always locked to match the direction implied by
  // weight/goalWeight (see _applyImpliedGoal), so delta and rate can never
  // point in opposite directions here — no mismatch case to handle.
  _updateEstimate(rate) {
    const weight     = parseFloat(this.weightInputTarget.value) || 0
    const goalWeight = parseFloat(this.goalWeightInputTarget.value) || 0

    this.estimateRowTarget.classList.add("hidden")

    if (rate === 0 || weight <= 0 || goalWeight <= 0) return

    const delta = goalWeight - weight
    if (delta === 0) return

    const weeks = Math.round(Math.abs(delta) / Math.abs(rate))
    this.estimateValueTarget.textContent = this.estimateTemplateValue
      .replace("__WEEKS__", weeks)
      .replace("__WEIGHT__", goalWeight)
    this.estimateRowTarget.classList.remove("hidden")
  }
}
