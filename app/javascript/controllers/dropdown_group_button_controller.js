import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown-group-button"
export default class extends Controller {
  static targets = ["buttonList"]

  connect() {
    this._boundClose = this.closeButtonList.bind(this)
    this._buttonListOpened = false
  }

  disconnect() {
    window.removeEventListener("click", this._boundClose)
    this._buttonListOpened = false
  }

  openButtonList(event) {
    event.stopPropagation();

    if (this._buttonListOpened) {
      return this.closeButtonList(event);
    }

    this._buttonListOpened = true;
    this.buttonListTarget.classList.remove("hidden");
    window.addEventListener("click", this._boundClose);
  }

  closeButtonList(event) {
    if (this.hasButtonListTarget && this.buttonListTarget.contains(event.target) && event.target) {
      return;
    }
    this._buttonListOpened = false;
    if (this.hasButtonListTarget) {
      this.buttonListTarget.classList.add("hidden");
    }
    window.removeEventListener("click", this._boundClose);
  }
}
