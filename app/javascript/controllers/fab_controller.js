import { Controller } from "@hotwired/stimulus"

// Speed-dial FAB: a circular toggle button that fans out N icon-only
// pastilles along a quarter-circle arc (90°=straight up, 180°=straight
// left), evenly re-spaced at runtime for however many pastilles are
// actually rendered (2-4, depending on server-side conditionals).
const ARC_START_DEG = 90
const ARC_END_DEG = 180
const RADIUS_PX = 92

export default class extends Controller {
  static targets = ["button", "icon", "item"]

  connect() {
    this._open = false
    this._boundOutsideClick = this._onOutsideClick.bind(this)
    this._boundKeydown = this._onKeydown.bind(this)
    this._layoutItems()
  }

  disconnect() {
    this._removeListeners()
  }

  toggle() {
    if (this._open) {
      this.close()
    } else {
      this._openMenu()
    }
  }

  close() {
    if (!this._open) return
    this._open = false
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.iconTarget.classList.remove("rotate-45")
    this.itemTargets.forEach((item) => {
      item.style.transitionDelay = "0ms"
      item.classList.remove("opacity-100", "scale-100", "translate-x-[var(--fab-tx)]", "translate-y-[var(--fab-ty)]")
      item.classList.add("opacity-0", "scale-50", "translate-x-0", "translate-y-0", "pointer-events-none")
    })
    this._removeListeners()
  }

  _openMenu() {
    this._open = true
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.iconTarget.classList.add("rotate-45")
    this.itemTargets.forEach((item, index) => {
      item.style.transitionDelay = `${index * 40}ms`
      item.classList.remove("opacity-0", "scale-50", "translate-x-0", "translate-y-0", "pointer-events-none")
      item.classList.add("opacity-100", "scale-100", "translate-x-[var(--fab-tx)]", "translate-y-[var(--fab-ty)]")
    })
    requestAnimationFrame(() => {
      document.addEventListener("click", this._boundOutsideClick)
      document.addEventListener("keydown", this._boundKeydown)
    })
  }

  _layoutItems() {
    const items = this.itemTargets
    const count = items.length
    if (count === 0) return

    items.forEach((item, index) => {
      const angleDeg = count === 1
        ? (ARC_START_DEG + ARC_END_DEG) / 2
        : ARC_START_DEG + index * ((ARC_END_DEG - ARC_START_DEG) / (count - 1))
      const angleRad = (angleDeg * Math.PI) / 180
      const tx = Math.round(RADIUS_PX * Math.cos(angleRad))
      const ty = Math.round(-RADIUS_PX * Math.sin(angleRad))
      item.style.setProperty("--fab-tx", `${tx}px`)
      item.style.setProperty("--fab-ty", `${ty}px`)
    })
  }

  _onOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  _onKeydown(event) {
    if (event.key === "Escape") this.close()
  }

  _removeListeners() {
    document.removeEventListener("click", this._boundOutsideClick)
    document.removeEventListener("keydown", this._boundKeydown)
  }
}
