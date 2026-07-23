import { Controller } from "@hotwired/stimulus"

// Requests that a collapsible section elsewhere on the page open itself,
// identified by its DOM id — e.g. the persistent fasting banner opening the
// calendar's fasting widget instead of just scrolling to it still collapsed.
export default class extends Controller {
  static values = { targetId: String }

  requestOpen() {
    document.dispatchEvent(new CustomEvent("collapsible:open-request", { detail: { id: this.targetIdValue } }))
  }
}
