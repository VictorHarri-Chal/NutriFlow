import { Controller } from "@hotwired/stimulus"

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
    Turbo.visit(`/calendars?date=${selectedDate}`)
  }
}
