import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Manages drag-to-reorder for any list of items.
// Usage:
//   data-controller="sortable-list"
//   data-sortable-list-url-value="<reorder_path>"
// Each item needs data-sortable-id="<id>" and a [data-drag-handle] child.
export default class extends Controller {
  static values = { url: String }

  connect() {
    this._sortable = Sortable.create(this.element, {
      handle:     "[data-drag-handle]",
      animation:  150,
      ghostClass: "sortable-ghost",
      dragClass:  "sortable-drag",
      onEnd:      () => this._persist()
    })
  }

  disconnect() {
    this._sortable?.destroy()
  }

  _persist() {
    const ids = Array.from(this.element.querySelectorAll("[data-sortable-id]"))
      .map(el => el.dataset.sortableId)

    fetch(this.urlValue, {
      method:  "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
      },
      body: JSON.stringify({ ids })
    })
  }
}
