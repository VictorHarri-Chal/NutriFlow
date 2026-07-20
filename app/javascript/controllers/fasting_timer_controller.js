import { Controller } from "@hotwired/stimulus"

const TICK_INTERVAL_MS = 30_000

export default class extends Controller {
  static targets = [
    "elapsedValue", "ring", "goalReachedBox", "remainingText", "bannerText"
  ]
  static values = {
    startedAt:         String,
    targetHours:       Number,
    remainingTemplate: String,
    bannerTemplate:    String
  }

  connect() {
    this.tick()
    this._timer = setInterval(() => this.tick(), TICK_INTERVAL_MS)
  }

  disconnect() {
    clearInterval(this._timer)
  }

  tick() {
    const elapsedHours   = (Date.now() - new Date(this.startedAtValue).getTime()) / 3_600_000
    const remainingHours = Math.max(this.targetHoursValue - elapsedHours, 0)
    const reachedTarget  = elapsedHours >= this.targetHoursValue
    const formatted      = formatDuration(elapsedHours)

    this.elapsedValueTargets.forEach((el) => { el.textContent = formatted })

    if (this.hasRingTarget) this._updateRing(elapsedHours)

    if (this.hasRemainingTextTarget && this.hasRemainingTemplateValue) {
      this.remainingTextTarget.textContent = this.remainingTemplateValue.replace("__DURATION__", formatDuration(remainingHours))
      this.remainingTextTarget.classList.toggle("hidden", reachedTarget)
    }

    if (this.hasBannerTextTarget && this.hasBannerTemplateValue) {
      this.bannerTextTarget.textContent = this.bannerTemplateValue.replace("__DURATION__", formatDuration(remainingHours))
    }

    if (this.hasGoalReachedBoxTarget) {
      this.goalReachedBoxTarget.classList.toggle("hidden", !reachedTarget)
    }
  }

  // Mirrors RingComponent's own dashoffset formula (circumference * (1 - ratio))
  // so the arc keeps advancing without a server round-trip.
  _updateRing(elapsedHours) {
    const circle = this.ringTarget.querySelector("svg circle:last-of-type")
    if (!circle) return

    const circumference = parseFloat(circle.getAttribute("stroke-dasharray"))
    const ratio = Math.min(elapsedHours / this.targetHoursValue, 1)
    circle.setAttribute("stroke-dashoffset", (circumference * (1 - ratio)).toFixed(2))
  }
}

function formatDuration(hours) {
  const totalMinutes = Math.round(hours * 60)
  const h = Math.floor(totalMinutes / 60)
  const m = totalMinutes % 60
  return `${h}h${String(m).padStart(2, "0")}`
}
