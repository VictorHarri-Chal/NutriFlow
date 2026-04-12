import { Controller } from "@hotwired/stimulus"
import { visit } from "@hotwired/turbo"

export default class extends Controller {
  connect() {
    this._boundHandler = this.handleDateChange.bind(this)
    this.element.addEventListener('change', this._boundHandler)
  }

  disconnect() {
    this.element.removeEventListener('change', this._boundHandler)
  }

  handleDateChange(event) {
    const selectedDate = event.target.value
    visit(`/calendars?date=${selectedDate}`)
  }
}
