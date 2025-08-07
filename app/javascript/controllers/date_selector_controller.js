import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('change', this.handleDateChange.bind(this))
  }

  handleDateChange(event) {
    const selectedDate = event.target.value

    // Faire une requête AJAX
    fetch(`/calendars?date=${selectedDate}`, {
      headers: {
        'Accept': 'text/html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.text())
    .then(html => {
      // Mettre à jour l'URL sans recharger la page
      window.history.pushState({}, '', `/calendars?date=${selectedDate}`)

      // Mettre à jour le contenu
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      const newContent = doc.getElementById('calendar-content')

      if (newContent) {
        document.getElementById('calendar-content').innerHTML = newContent.innerHTML
      }

      // Mettre à jour le titre de la page
      const newTitle = doc.querySelector('h1')
      if (newTitle) {
        document.querySelector('h1').textContent = newTitle.textContent
      }
    })
    .catch(error => {
      console.error('Erreur lors du changement de date:', error)
    })
  }
}
