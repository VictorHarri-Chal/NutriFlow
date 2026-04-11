import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "ratingInput", "viewMode", "editMode"]
  static values = { currentRating: Number }

  connect() {
    this.updateStars(this.currentRatingValue)
  }

  // --- Toggle vue / édition ---

  edit() {
    this.viewModeTarget.classList.add("hidden")
    this.editModeTarget.classList.remove("hidden")
  }

  cancel() {
    this.editModeTarget.classList.add("hidden")
    this.viewModeTarget.classList.remove("hidden")
    // Remettre les étoiles à la valeur sauvegardée
    this.updateStars(this.currentRatingValue)
  }

  // --- Étoiles ---

  selectRating(event) {
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.ratingInputTarget.value = rating
    this.currentRatingValue = rating
    this.updateStars(rating)
  }

  hoverRating(event) {
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.updateStars(rating)
  }

  leaveStars() {
    this.updateStars(this.currentRatingValue)
  }

  updateStars(rating) {
    this.starTargets.forEach((star, index) => {
      const icon = star.querySelector('i')
      if (!icon) return
      if (index < rating) {
        icon.className = 'fas fa-star text-brand'
      } else {
        icon.className = 'fas fa-star text-ink-subtle'
      }
    })
  }
}
