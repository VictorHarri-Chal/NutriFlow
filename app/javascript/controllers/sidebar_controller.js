import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["topMenu", "desktopSideMenu", "desktopSideBarOpeningButton", "navbar"];

  desktopToggle() {
    const sidebar = this.desktopSideMenuTarget;
    const isOpen = sidebar.style.transform !== "translateX(-100%)";

    if (isOpen) {
      sidebar.style.transform = "translateX(-100%)";
      this.desktopSideBarOpeningButtonTarget.classList.remove("hidden");
      if (this.topMenuTarget) this.topMenuTarget.classList.remove("md:pl-64");
      if (this.navbarTarget) this.navbarTarget.classList.remove("md:pl-64");
    } else {
      sidebar.style.transform = "";
      this.desktopSideBarOpeningButtonTarget.classList.add("hidden");
      if (this.topMenuTarget) this.topMenuTarget.classList.add("md:pl-64");
      if (this.navbarTarget) this.navbarTarget.classList.add("md:pl-64");
    }
  }
}
