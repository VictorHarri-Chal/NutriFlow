import { Controller } from "@hotwired/stimulus"

// Modern product-screenshot carousel: prev/next, clickable dots, touch swipe,
// gentle autoplay with a visible pause/play control (keyboard + touch reachable)
// and hover-pause. Respects prefers-reduced-motion (no autoplay, no transition).
export default class extends Controller {
  static targets = ["track", "slide", "dot", "playButton", "playIcon"]
  static values = { index: { type: Number, default: 0 }, interval: { type: Number, default: 6000 } }

  connect() {
    this._reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this._playing = !this._reduced && this.slideTargets.length > 1
    this._hovered = false
    if (this._reduced) {
      this.trackTarget.classList.remove("transition-transform", "duration-500", "ease-out")
    }
    this._syncPlayButton()
    this._render()
    this._start()
  }

  disconnect() {
    this._stop()
  }

  next() { this._goTo(this.indexValue + 1) }
  prev() { this._goTo(this.indexValue - 1) }

  select(event) {
    const i = parseInt(event.currentTarget.dataset.index, 10)
    if (!Number.isNaN(i)) this._goTo(i)
  }

  // Transient hover pause (mouse only).
  pause() { this._hovered = true; this._stop() }
  resume() { this._hovered = false; this._start() }

  // Explicit, keyboard/touch-reachable play/pause toggle.
  toggle() {
    this._playing = !this._playing
    this._syncPlayButton()
    this._start()
  }

  dragStart(event) {
    this._startX = event.clientX
    this._dragging = true
  }

  dragEnd(event) {
    if (!this._dragging) return
    this._dragging = false
    const dx = event.clientX - this._startX
    if (Math.abs(dx) > 50) (dx < 0 ? this.next() : this.prev())
  }

  _goTo(i) {
    const count = this.slideTargets.length
    this.indexValue = (i + count) % count
    this._render()
    this._start() // honours _playing / _hovered, so it won't resume while paused
  }

  _render() {
    this.trackTarget.style.transform = `translateX(-${this.indexValue * 100}%)`
    this.slideTargets.forEach((slide, i) => {
      slide.setAttribute("aria-hidden", i !== this.indexValue)
    })
    this.dotTargets.forEach((dot, i) => {
      const active = i === this.indexValue
      dot.classList.toggle("w-6", active)
      dot.classList.toggle("bg-brand", active)
      dot.classList.toggle("w-2", !active)
      dot.classList.toggle("bg-surface-border", !active)
      if (active) {
        dot.setAttribute("aria-current", "true")
      } else {
        dot.removeAttribute("aria-current")
      }
    })
  }

  _start() {
    this._stop()
    if (this._playing && !this._hovered && this.slideTargets.length > 1) {
      this._timer = setInterval(() => this.next(), this.intervalValue)
    }
  }

  _stop() {
    if (this._timer) {
      clearInterval(this._timer)
      this._timer = null
    }
  }

  _syncPlayButton() {
    if (!this.hasPlayIconTarget) return
    this.playIconTarget.classList.toggle("fa-pause", this._playing)
    this.playIconTarget.classList.toggle("fa-play", !this._playing)
    if (this.hasPlayButtonTarget) {
      const btn = this.playButtonTarget
      btn.setAttribute("aria-label", this._playing ? btn.dataset.pauseLabel : btn.dataset.playLabel)
    }
  }
}
