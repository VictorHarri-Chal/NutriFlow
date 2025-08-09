import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content"]
  static classes = ["active", "inactive"]
  static values = {
    activeTab: String,
    activeBorder: String,
    activeText: String,
    inactiveBorder: String,
    inactiveText: String
  }

  connect() {
    // Définir les classes par défaut si elles ne sont pas spécifiées
    this.activeBorderValue = this.activeBorderValue || "border-blue-600"
    this.activeTextValue = this.activeTextValue || "text-blue-600"
    this.inactiveBorderValue = this.inactiveBorderValue || "border-transparent"
    this.inactiveTextValue = this.inactiveTextValue || "text-gray-500"

    // Activer le premier onglet par défaut si aucun n'est actif
    if (!this.activeTabValue && this.tabTargets.length > 0) {
      this.switchToTab(this.tabTargets[0])
    }
  }

  switchTab(event) {
    event.preventDefault()
    const clickedTab = event.currentTarget
    this.switchToTab(clickedTab)
  }

  switchToTab(activeTab) {
    // Désactiver tous les onglets
    this.tabTargets.forEach(tab => {
      tab.classList.remove("active", this.activeBorderValue, this.activeTextValue)
      tab.classList.add(this.inactiveBorderValue, this.inactiveTextValue)
    })

    // Activer l'onglet sélectionné
    activeTab.classList.add("active", this.activeBorderValue, this.activeTextValue)
    activeTab.classList.remove(this.inactiveBorderValue, this.inactiveTextValue)

    // Cacher tous les contenus
    this.contentTargets.forEach(content => {
      content.classList.add("hidden")
    })

    // Afficher le contenu correspondant
    const tabId = activeTab.dataset.tab
    const activeContent = this.contentTargets.find(content =>
      content.id === `${tabId}-tab`
    )

    if (activeContent) {
      activeContent.classList.remove("hidden")
    }

    // Mettre à jour la valeur de l'onglet actif
    this.activeTabValue = tabId
  }
}
