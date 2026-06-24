import { Controller } from "@hotwired/stimulus"

// Debounced auto-submit for search forms.
// Attach to the <form> element; add data-action="input->search#input" on inputs.
export default class extends Controller {
  static targets = ["input", "clear"]
  static values  = { delay: { type: Number, default: 300 } }

  connect() {
    this._timer = null
    this._updateClear()
  }

  disconnect() { clearTimeout(this._timer) }

  input() {
    clearTimeout(this._timer)
    this._updateClear()
    this._timer = setTimeout(() => {
      this._syncFilterParams()
      this.element.requestSubmit()
    }, this.delayValue)
  }

  clear(event) {
    event.preventDefault()
    clearTimeout(this._timer)
    this.inputTarget.value = ""
    this._updateClear()
    this._syncFilterParams()
    this.element.requestSubmit()
  }

  // Affiche ou cache le bouton X selon que l'input est vide ou non
  _updateClear() {
    if (!this.hasClearTarget || !this.hasInputTarget) return
    this.clearTarget.classList.toggle("hidden", this.inputTarget.value.length === 0)
  }

  // Lit les filtres/tris actifs depuis l'URL courante et les injecte dans le form
  // pour qu'une recherche reste cumulative avec les filtres et tris déjà appliqués.
  _syncFilterParams() {
    const current = new URLSearchParams(window.location.search)
    const keys = ["favorites", "in_stock", "out_of_stock", "label_id", "category", "sort_usages", "q[s]"]

    Array.from(this.element.querySelectorAll('input[type="hidden"]'))
      .filter(el => keys.includes(el.name))
      .forEach(el => el.remove())

    keys.forEach(key => {
      const value = current.get(key)
      if (value !== null) {
        const input = document.createElement("input")
        input.type = "hidden"
        input.name = key
        input.value = value
        this.element.appendChild(input)
      }
    })
  }
}
