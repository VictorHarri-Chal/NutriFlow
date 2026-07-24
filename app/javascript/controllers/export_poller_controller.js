import { Controller } from "@hotwired/stimulus"

// Polls the export's status endpoint while it's being generated. Each tick asks
// for the turbo_stream variant and re-renders the #export_status region; once the
// server renders the "ready" (or "failed") state the poller element is replaced,
// disconnect() fires, and polling stops.
export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 2000 } }

  connect() {
    this._timer = setInterval(() => this._check(), this.intervalValue)
  }

  disconnect() {
    if (this._timer) clearInterval(this._timer)
  }

  async _check() {
    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "text/vnd.turbo-stream.html" }
      })
      if (!response.ok) return

      const html = await response.text()
      if (html.includes("<turbo-stream")) Turbo.renderStreamMessage(html)
    } catch (_error) {
      // Transient network error — keep polling on the next tick.
    }
  }
}
