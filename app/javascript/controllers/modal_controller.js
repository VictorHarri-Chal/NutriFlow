import { Controller } from "@hotwired/stimulus"

// Generic modal shell — injected by the server (turbo_stream.update) into a
// root div, removed from the DOM on close rather than hidden (content is
// always fresh next time it's opened). Used by history/week-generation/
// suggestions modals; feature-specific behavior (e.g. selection counting)
// lives in its own controller stacked on the same element.
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    requestAnimationFrame(() => {
      this.panelTarget.classList.remove("scale-95", "opacity-0")
      this.panelTarget.classList.add("scale-100", "opacity-100")
    })
    document.body.classList.add("overflow-hidden")
  }

  disconnect() {
    document.body.classList.remove("overflow-hidden")
  }

  close() {
    this.panelTarget.classList.remove("scale-100", "opacity-100")
    this.panelTarget.classList.add("scale-95", "opacity-0")
    setTimeout(() => this.element.remove(), 200)
  }

  handleBackdropClick(event) {
    // Ignore les clics dont la cible a été retirée du DOM pendant le traitement
    // (ex. une option de custom-select reconstruite par innerHTML) : ce n'est
    // pas un clic sur le fond, et panelTarget.contains() renverrait un faux
    // négatif sur un nœud détaché, fermant la modale à tort.
    if (!document.contains(event.target)) return

    // Le backdrop est un enfant de this.element (pas this.element lui-même),
    // donc on ferme dès que le clic n'a pas eu lieu à l'intérieur du panneau —
    // couvre le backdrop et tout espace vide autour, jamais le contenu.
    if (this.hasPanelTarget && !this.panelTarget.contains(event.target)) {
      this.close()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
