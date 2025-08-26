import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown-group-button"
export default class extends Controller {
  static targets = ["buttonList"]

  openButtonList(event) {
    event.stopPropagation();

    if (this._buttonListOpened) {
      return this.closeButtonList(event);
    }

    this._buttonListOpened = true;
    this.buttonListTarget.classList.remove("hidden");
    this.closeButtonListOnClickOutside = this.closeButtonList.bind(this);
    window.addEventListener("click", this.closeButtonListOnClickOutside);
  }

  closeButtonList(event) {
    if (this.hasButtonListTarget && this.buttonListTarget.contains(event.target) && event.target) {
      return;
    }
    this._buttonListOpened = false;
    if (this.hasButtonListTarget) {
      this.buttonListTarget.classList.add("hidden");
    }
    window.removeEventListener("click", this.closeButtonListOnClickOutside);
    this.closeButtonListOnClickOutside = null;
  }
}
