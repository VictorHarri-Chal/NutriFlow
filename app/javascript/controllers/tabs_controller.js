import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content"]
  static values = {
    activeTab: String
  }

  connect() {
    if (this.activeTabValue) {
      const activeTab = this.tabTargets.find(tab => tab.dataset.tab === this.activeTabValue)
      if (activeTab) {
        this.switchToTab(activeTab)
        return
      }
    }
    if (this.tabTargets.length > 0) {
      this.switchToTab(this.tabTargets[0])
    }

    this._boundCloseOpenEdits = this.closeOpenEdits.bind(this)
    document.addEventListener("turbo:before-cache", this._boundCloseOpenEdits)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this._boundCloseOpenEdits)
  }

  switchTab(event) {
    event.preventDefault()
    this.closeOpenEdits()
    this.switchToTab(event.currentTarget)
  }

  // Closes any inline edit form left open (e.g. a group/label being renamed)
  // before switching tabs or letting Turbo cache the current page — otherwise
  // the form would still show, hidden, when the tab/page is revisited.
  closeOpenEdits() {
    this.element.querySelectorAll('[data-role="cancel-edit"]').forEach(link => link.click())
  }

  switchToTab(activeTab) {
    // Nav items: read active/inactive classes from data attributes on each tab
    this.tabTargets.forEach(tab => {
      const active   = (tab.dataset.activeClasses   || "").split(" ").filter(Boolean)
      const inactive = (tab.dataset.inactiveClasses || "").split(" ").filter(Boolean)
      tab.classList.remove(...active)
      tab.classList.add(...inactive)
    })

    const active   = (activeTab.dataset.activeClasses   || "").split(" ").filter(Boolean)
    const inactive = (activeTab.dataset.inactiveClasses || "").split(" ").filter(Boolean)
    activeTab.classList.remove(...inactive)
    activeTab.classList.add(...active)

    // Content panels
    this.contentTargets.forEach(content => content.classList.add("hidden"))
    const activeContent = this.contentTargets.find(c => c.id === `${activeTab.dataset.tab}-tab`)
    if (activeContent) activeContent.classList.remove("hidden")

    this.activeTabValue = activeTab.dataset.tab
  }
}
