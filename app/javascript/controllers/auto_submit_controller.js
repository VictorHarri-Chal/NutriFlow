import { Controller } from "@hotwired/stimulus"

// Submits the parent form on blur or Enter keydown via a direct fetch.
// Processes Turbo Stream responses so the server can update read-only
// summary elements (e.g. exercise meta block) without touching input focus.
// Silent responses (empty body or no <turbo-stream>) are ignored.
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
    }).then(r => r.text()).then(html => {
      if (html.includes("<turbo-stream")) Turbo.renderStreamMessage(html)
    }).catch(() => {})
  }
}
