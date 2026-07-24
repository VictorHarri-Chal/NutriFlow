import { Controller } from "@hotwired/stimulus"

// When the "ready" state appears (rendered once by the poller when the file is
// done), trigger the download automatically. The link stays visible for a manual
// re-download. connect() fires once per insertion, so it downloads only on the
// live ready transition — never on a plain page reload (idle state renders empty).
export default class extends Controller {
  static targets = ["link"]
  static values = { url: String }

  connect() {
    if (this.hasLinkTarget) {
      this.linkTarget.click()
    } else if (this.hasUrlValue) {
      window.location.href = this.urlValue
    }
  }
}
