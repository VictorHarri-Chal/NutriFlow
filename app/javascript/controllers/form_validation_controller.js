import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    this.updateButtonState()
  }

  updateButtonState() {
    const isEmpty = this.inputTarget.value.trim() === ''
    this.submitTarget.disabled = isEmpty
  }

  // Méthode appelée quand l'utilisateur tape dans le champ
  input() {
    this.updateButtonState()
  }

  // Méthode appelée quand l'utilisateur relâche une touche
  keyup() {
    this.updateButtonState()
  }
}
