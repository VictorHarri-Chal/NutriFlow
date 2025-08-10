import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "message", "confirmButton", "cancelButton"]
  static values = {
    message: String,
    url: String,
    method: { type: String, default: "delete" }
  }

  connect() {
    if (!this.hasModalTarget) {
      this.createModal()
    }

    // Gestion de la touche Escape
    this.handleEscape = this.handleEscape.bind(this)
  }

  show(event) {
    event.preventDefault()

    const link = event.currentTarget
    const message = link.dataset.confirmMessage || this.messageValue || "Es-tu sûr de vouloir supprimer cet élément ?"
    const url = link.href || this.urlValue
    const method = link.dataset.turboMethod || this.methodValue || "delete"

    this.messageTarget.textContent = message
    this.confirmButtonTarget.dataset.url = url
    this.confirmButtonTarget.dataset.method = method

    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")

    // Animation d'entrée
    requestAnimationFrame(() => {
      const modalContent = this.modalTarget.querySelector('[data-confirm-target="modalContent"]')
      if (modalContent) {
        modalContent.classList.remove("scale-95", "opacity-0")
        modalContent.classList.add("scale-100", "opacity-100")
      }
    })

    // Ajouter l'écouteur pour Escape
    document.addEventListener('keydown', this.handleEscape)
  }

  hide() {
    // Animation de sortie
    const modalContent = this.modalTarget.querySelector('[data-confirm-target="modalContent"]')
    if (modalContent) {
      modalContent.classList.remove("scale-100", "opacity-100")
      modalContent.classList.add("scale-95", "opacity-0")
    }

    // Attendre la fin de l'animation avant de cacher
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }, 200)

    // Retirer l'écouteur Escape
    document.removeEventListener('keydown', this.handleEscape)
  }

  confirm(event) {
    const button = event.currentTarget
    const url = button.dataset.url
    const method = button.dataset.method

    this.hide()
    this.submitForm(url, method)
  }

  submitForm(url, method) {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = url

    const inputs = [
      { name: '_method', value: method.toUpperCase() },
      { name: 'authenticity_token', value: this.getCsrfToken() }
    ]

    inputs.forEach(({ name, value }) => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = name
      input.value = value
      form.appendChild(input)
    })

    document.body.appendChild(form)
    form.submit()
  }

  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  }

  handleEscape(event) {
    if (event.key === 'Escape') {
      this.hide()
    }
  }

  handleBackdropClick(event) {
    if (event.target === this.modalTarget) {
      this.hide()
    }
  }

  createModal() {
    const modal = document.createElement("div")
    modal.className = "fixed inset-0 z-50 overflow-y-auto hidden"
    modal.setAttribute("data-confirm-target", "modal")
    modal.innerHTML = this.modalTemplate()

    document.body.appendChild(modal)
    this.element.appendChild(modal)
  }

  modalTemplate() {
    return `
      <div class="fixed inset-0 z-50 flex items-center justify-center p-4" data-action="click->confirm#handleBackdropClick">
        <!-- Backdrop avec animation -->
        <div class="absolute inset-0 bg-black/50 backdrop-blur-sm transition-opacity duration-300 ease-in-out"
             aria-hidden="true"></div>

        <!-- Modal avec animation -->
        <div class="relative w-full max-w-md transform overflow-hidden rounded-2xl bg-white shadow-2xl transition-all duration-300 ease-out scale-95 opacity-0"
             data-confirm-target="modalContent">
          <!-- Header avec icône -->
          <div class="flex items-center justify-center p-6 pb-4">
            <div class="flex-shrink-0">
              <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-red-100">
                <i class="fas fa-exclamation-triangle text-red-600 text-2xl"></i>
              </div>
            </div>
          </div>

          <!-- Contenu -->
          <div class="px-6 pb-6">
            <div class="text-center">
              <h3 class="text-lg font-semibold leading-6 text-gray-900 mb-2">
                Confirmation requise
              </h3>
              <div class="mt-2">
                <p class="text-sm leading-6 text-gray-600" data-confirm-target="message">
                  Es-tu sûr de vouloir supprimer cet élément ?
                </p>
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="bg-gray-50 px-6 py-4 flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-3 gap-3">
            <button type="button"
                    class="inline-flex w-full justify-center rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-medium text-gray-700 shadow-sm transition-all duration-200 hover:bg-gray-50 hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 sm:w-auto"
                    data-action="click->confirm#hide"
                    data-confirm-target="cancelButton">
              Annuler
            </button>
            <button type="button"
                    class="inline-flex w-full justify-center rounded-lg border border-transparent bg-red-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-all duration-200 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 sm:w-auto"
                    data-action="click->confirm#confirm"
                    data-confirm-target="confirmButton">
              Confirmer
            </button>
          </div>
        </div>
      </div>
    `
  }
}
