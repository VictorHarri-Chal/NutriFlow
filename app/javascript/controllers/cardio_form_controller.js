import { Controller } from "@hotwired/stimulus"

// Manages the cardio session form:
// - shows/hides machine-specific param fields when the machine select changes
// - updates the resistance level label as the slider moves
export default class extends Controller {
  static targets = ["block"]

  connect() {
    this.blockTargets.forEach(block => this.#refreshFields(block))
  }

  // Called when the machine <select> changes (dispatched by custom-select controller)
  machineChanged(event) {
    const block = event.target.closest("[data-cardio-form-target='block']")
    this.#refreshFields(block)
  }

  // Updates the numeric label beside the resistance range slider
  updateResistanceLabel(event) {
    const slider = event.target
    const label  = slider.closest("[data-field-group='resistance']")
                         ?.querySelector("[data-resistance-label]")
    if (label) label.textContent = slider.value
  }

  // ── Private ────────────────────────────────────────────────────────────────

  #refreshFields(block) {
    if (!block) return
    const select  = block.querySelector("[data-machine-select]")
    if (!select) return
    const machine = select.value

    const show = (selector, visible) => {
      const el = block.querySelector(selector)
      if (!el) return
      el.classList.toggle("hidden", !visible)
      el.querySelectorAll("input").forEach(input => {
        input.disabled = !visible
      })
    }

    show("[data-field-group='speed']",      ["treadmill", "outdoor_run"].includes(machine))
    show("[data-field-group='incline']",    machine === "treadmill")
    show("[data-field-group='resistance']", ["bike", "elliptical", "rower", "ski_erg", "stairmaster"].includes(machine))
    show("[data-field-group='distance']",   ["outdoor_run", "swimming"].includes(machine))
  }
}
