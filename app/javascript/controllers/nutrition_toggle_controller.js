import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["totalBtn", "per100Btn", "totalVal", "per100Val"]

  showTotal() {
    this.totalValTargets.forEach(el => el.classList.remove("hidden"))
    this.per100ValTargets.forEach(el => el.classList.add("hidden"))
    this._setActive(this.totalBtnTarget)
    this._setInactive(this.per100BtnTarget)
  }

  showPer100() {
    this.totalValTargets.forEach(el => el.classList.add("hidden"))
    this.per100ValTargets.forEach(el => el.classList.remove("hidden"))
    this._setActive(this.per100BtnTarget)
    this._setInactive(this.totalBtnTarget)
  }

  _setActive(btn) {
    btn.classList.add("bg-surface-raised", "text-ink-primary", "shadow-sm")
    btn.classList.remove("text-ink-subtle")
  }

  _setInactive(btn) {
    btn.classList.remove("bg-surface-raised", "text-ink-primary", "shadow-sm")
    btn.classList.add("text-ink-subtle")
  }
}
