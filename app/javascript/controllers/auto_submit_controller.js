import { Controller } from "@hotwired/stimulus"

// Submits the parent form on blur or Enter keydown via a direct fetch —
// bypassing Turbo's FormSubmission pipeline entirely so it cannot
// manipulate focus in any way. Fire-and-forget: the response (a silent
// Turbo Stream) is never processed, which is fine for auto-save fields.
export default class extends Controller {
  submit(event) {
    if (event.type === "keydown") event.preventDefault()
    const form = this.element.closest("form")
    if (!form) return

    const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
    fetch(form.action, {
      method: form.getAttribute("method") || "post",
      body: new FormData(form),
      headers: {
        ...(csrf ? { "X-CSRF-Token": csrf } : {}),
        "Accept": "text/vnd.turbo-stream.html, text/html"
      }
    }).catch(() => {})
  }
}
