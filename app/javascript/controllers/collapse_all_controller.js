import { Controller } from "@hotwired/stimulus"

// Broadcasts a request for every collapsible section on the page to close —
// e.g. the calendar's "collapse all" button. See collapsible_controller.js's
// listener for "collapsible:close-all".
export default class extends Controller {
  closeAll() {
    document.dispatchEvent(new CustomEvent("collapsible:close-all"))
  }
}
