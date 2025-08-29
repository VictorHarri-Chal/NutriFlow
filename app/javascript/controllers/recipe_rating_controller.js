import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "ratingInput"]
  static values = { currentRating: Number }

  connect() {
    this.updateStars(this.currentRatingValue)
  }

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
      if (index < rating) {
        icon.className = 'fas fa-star text-yellow-500'
      } else {
        icon.className = 'fas fa-star text-gray-300'
      }
    })
  }
}
