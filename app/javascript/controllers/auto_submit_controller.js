import { Controller } from "@hotwired/stimulus"

// Submits the parent form on blur or Enter keydown via a direct fetch.
// Processes Turbo Stream responses so the server can update read-only
// summary elements (e.g. exercise meta block) without touching input focus.
// Silent responses (empty body or no <turbo-stream>) are ignored.
//
// Several fields of the same form can each carry their own auto-submit
// controller instance (one per input). Blurring them in quick succession
// fires independent fetches with no ordering guarantee — a slower earlier
// request could land after a later one and overwrite it with stale data.
// Requests for a given form are therefore queued so they always resolve
// in the order they were fired, one at a time.
export default class extends Controller {
  submit(event) {
    if (event.type === "keydown") event.preventDefault()
    const form = this.element.closest("form")
    if (!form) return

    const run = () => this._send(form)
    form._autoSubmitQueue = (form._autoSubmitQueue || Promise.resolve()).then(run, run)
  }

  _send(form) {
    const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
    return fetch(form.action, {
      method: form.getAttribute("method") || "post",
      body: new FormData(form),
      headers: {
        ...(csrf ? { "X-CSRF-Token": csrf } : {}),
        "Accept": "text/vnd.turbo-stream.html, text/html"
      }
    }).then(r => r.text()).then(html => {
      if (html.includes("<turbo-stream")) Turbo.renderStreamMessage(html)
    }).catch(() => {})
  }
}
