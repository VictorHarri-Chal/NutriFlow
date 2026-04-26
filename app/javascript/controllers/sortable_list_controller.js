import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Manages drag-to-reorder for any list of items, including cross-list moves.
// Usage:
//   data-controller="sortable-list"
//   data-sortable-list-url-value="<reorder_path>"
//   data-sortable-list-move-base-value="<base_path_for_move>"  (optional, enables cross-list)
//   data-sortable-list-group-value="<shared_group_name>"       (optional, enables cross-list)
//   data-sortable-list-day-id-value="<day_id>"                 (optional, used for move payload)
// Each item needs data-sortable-id="<id>" and a [data-drag-handle] child.
export default class extends Controller {
  static values = { url: String, moveBase: String, group: String, dayId: String }

  connect() {
    const groupName = this.hasGroupValue ? this.groupValue : null

    this._sortable = Sortable.create(this.element, {
      handle:     "[data-drag-handle]",
      animation:  150,
      ghostClass: "sortable-ghost",
      dragClass:  "sortable-drag",
      group:      groupName ? { name: groupName, pull: true, put: true } : undefined,
      onEnd:      (event) => this._onEnd(event)
    })
  }

  disconnect() {
    this._sortable?.destroy()
  }

  _onEnd(event) {
    if (event.from === event.to) {
      // Same list: standard reorder
      this._persist()
    } else {
      // Cross-list: the SOURCE controller owns the server call
      // (it holds the correct moveBaseValue for the exercise's current day)
      const exerciseId  = event.item.dataset.sortableId
      const targetDayId = event.to.dataset.sortableListDayIdValue
      const newPosition = event.newIndex
      this._move(exerciseId, targetDayId, newPosition)
    }
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
      body:   JSON.stringify({ ids }),
      signal: AbortSignal.timeout(5000)
    }).catch(err => {
      if (err.name !== "AbortError" && err.name !== "TimeoutError") {
        console.error("[sortable-list] Reorder failed:", err)
      }
    })
  }

  _move(exerciseId, targetDayId, newPosition) {
    if (!this.hasMoveBaseValue) return

    // Source day base path + exercise id + /move
    const url = `${this.moveBaseValue}/${exerciseId}/move`

    fetch(url, {
      method:  "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Accept":        "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
      },
      body:   JSON.stringify({ target_day_id: targetDayId, position: newPosition }),
      signal: AbortSignal.timeout(5000)
    })
      .then(response => {
        if (!response.ok) throw new Error(`Move failed: ${response.status}`)
        return response.text()
      })
      .then(html => {
        if (html) Turbo.renderStreamMessage(html)
      })
      .catch(err => {
        if (err.name !== "AbortError" && err.name !== "TimeoutError") {
          console.error("[sortable-list] Move failed:", err)
        }
      })
  }
}
