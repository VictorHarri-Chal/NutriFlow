import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["topMenu", "desktopSideMenu", "desktopSideBarOpeningButton", "navbar"];

  desktopToggle() {
    this.desktopSideMenuTarget.classList.toggle("md:flex");
    this.desktopSideBarOpeningButtonTarget.classList.toggle("hidden");
    if (this.topMenuTarget) this.topMenuTarget.classList.toggle("md:pl-64");
    if (this.navbarTarget) this.navbarTarget.classList.toggle("md:pl-64");
  }
}
