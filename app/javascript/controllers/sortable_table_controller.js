import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "row"]
  static values = {
    url: String,
    currentSort: String,
    currentDirection: String
  }

  connect() {
    this.updateSortIcons()
  }

  sort(event) {
    event.preventDefault()

    const column = event.currentTarget.dataset.column
    const newDirection = this.getNextDirection(column)

    this.updateURL(column, newDirection)
  }

  getNextDirection(column) {
    if (this.currentSortValue === column) {
      return this.currentDirectionValue === 'asc' ? 'desc' : 'asc'
    }
    return 'asc'
  }

  updateURL(column, direction) {
    const url = new URL(window.location)
    url.searchParams.set('sort_by', column)
    url.searchParams.set('direction', direction)

    // Préserver les autres paramètres (comme la recherche)
    const currentParams = new URLSearchParams(window.location.search)
    currentParams.forEach((value, key) => {
      if (key !== 'sort_by' && key !== 'direction') {
        url.searchParams.set(key, value)
      }
    })

    window.location.href = url.toString()
  }

  updateSortIcons() {
    this.headerTargets.forEach(header => {
      const column = header.dataset.column
      const icon = header.querySelector('.sort-icon')

      if (icon) {
        if (this.currentSortValue === column) {
          icon.className = `fas sort-icon ${this.currentDirectionValue === 'asc' ? 'fa-sort-up' : 'fa-sort-down'} ml-1`
        } else {
          icon.className = 'fas fa-sort sort-icon ml-1'
        }
      }
    })
  }
}
