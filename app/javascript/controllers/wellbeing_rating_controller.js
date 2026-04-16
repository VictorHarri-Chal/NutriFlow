import { Controller } from "@hotwired/stimulus"

const COLORS = {
  amber: {
    active: ["bg-amber-400/70", "border-amber-400/90", "text-amber-300", "font-bold"],
    filled: ["bg-amber-400/25", "border-amber-400/35", "text-amber-400/60"],
    empty:  ["bg-surface-hover/30", "border-surface-border/30", "text-ink-subtle/30"],
  },
  green: {
    active: ["bg-green-500/65", "border-green-500/85", "text-green-300", "font-bold"],
    filled: ["bg-green-500/20", "border-green-500/30", "text-green-400/60"],
    empty:  ["bg-surface-hover/30", "border-surface-border/30", "text-ink-subtle/30"],
  },
  blue: {
    active: ["bg-blue-500/65", "border-blue-500/85", "text-blue-300", "font-bold"],
    filled: ["bg-blue-500/20", "border-blue-500/30", "text-blue-400/60"],
    empty:  ["bg-surface-hover/30", "border-surface-border/30", "text-ink-subtle/30"],
  },
}

export default class extends Controller {
  static values = {
    selected: { type: Number, default: 0 },
    color:    { type: String, default: "amber" }
  }
  static targets = ["cell"]

  connect() {
    this._apply(this.selectedValue)
  }

  // Appelé au mouseenter sur chaque label (data-value="N")
  preview(event) {
    this._apply(parseInt(event.currentTarget.dataset.value), true)
  }

  // Appelé au mouseleave sur le container
  reset() {
    this._apply(this.selectedValue)
  }

  // Appelé au change sur le radio input (data-value="N" sur le label parent)
  select(event) {
    const val = parseInt(event.target.value)
    this.selectedValue = val
    this._apply(val)
  }

  _apply(activeVal, isHover = false) {
    const scheme = COLORS[this.colorValue] || COLORS.amber
    const all    = [...scheme.active, ...scheme.filled, ...scheme.empty]

    this.cellTargets.forEach(cell => {
      const cellVal = parseInt(cell.dataset.value)

      all.forEach(cls => cell.classList.remove(cls))

      let state
      if (isHover) {
        // On hover: all filled cells ≤ hovered get filled style (same as before)
        state = cellVal <= activeVal ? "filled" : "empty"
      } else {
        // On select: exact cell = active, below = filled, above = empty
        if (cellVal === activeVal)     state = "active"
        else if (cellVal < activeVal)  state = "filled"
        else                           state = "empty"
      }

      scheme[state].forEach(cls => cell.classList.add(cls))
    })
  }
}
