import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "ratingInput", "viewMode", "editMode", "editTrigger", "editActions", "commentInput", "submitBtn"]
  static values = { currentRating: Number }

  connect() {
    this.updateStars(this.currentRatingValue)
  }

  // ── Toggle vue / édition ──────────────────────────────────────────

  edit() {
    this.initialRating  = this.currentRatingValue
    this.initialComment = this.hasCommentInputTarget ? this.commentInputTarget.value : ""
    if (this.hasViewModeTarget)    this.viewModeTarget.classList.add("hidden")
    if (this.hasEditModeTarget)    this.editModeTarget.classList.remove("hidden")
    if (this.hasEditTriggerTarget) this.editTriggerTarget.classList.add("hidden")
    if (this.hasEditActionsTarget) this.editActionsTarget.classList.remove("hidden")
    this._checkDirty()
  }

  cancel() {
    if (this.hasEditModeTarget)    this.editModeTarget.classList.add("hidden")
    if (this.hasViewModeTarget)    this.viewModeTarget.classList.remove("hidden")
    if (this.hasEditTriggerTarget) this.editTriggerTarget.classList.remove("hidden")
    if (this.hasEditActionsTarget) this.editActionsTarget.classList.add("hidden")
    this.currentRatingValue = this.initialRating
    this.updateStars(this.currentRatingValue)
  }

  // ── Étoiles ──────────────────────────────────────────────────────

  selectRating(event) {
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.ratingInputTarget.value = rating
    this.currentRatingValue = rating
    this.updateStars(rating)
    this._checkDirty()
  }

  hoverRating(event) {
    this.updateStars(parseInt(event.currentTarget.dataset.rating))
  }

  leaveStars() {
    this.updateStars(this.currentRatingValue)
  }

  updateStars(rating) {
    this.starTargets.forEach((star, index) => {
      const icon = star.querySelector("i")
      if (!icon) return
      icon.className = index < rating ? "fas fa-star text-brand" : "fas fa-star text-ink-subtle"
    })
  }

  // ── Dirty check ──────────────────────────────────────────────────

  checkDirty() {
    this._checkDirty()
  }

  _checkDirty() {
    if (!this.hasSubmitBtnTarget) return
    const comment = this.hasCommentInputTarget ? this.commentInputTarget.value : ""
    const dirty   = this.currentRatingValue !== this.initialRating || comment !== this.initialComment
    this.submitBtnTarget.disabled = !dirty
  }
}
