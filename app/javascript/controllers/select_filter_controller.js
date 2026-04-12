import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "select"]

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    const select = this.selectTarget
    const options = Array.from(select.options)

    options.forEach(option => {
      if (option.value === "") {
        // Always show the blank placeholder
        return
      }
      const matches = option.text.toLowerCase().includes(query)
      option.hidden = !matches
    })

    // If the currently selected option is now hidden, reset to blank
    const selected = select.options[select.selectedIndex]
    if (selected && selected.hidden) {
      select.value = ""
    }
  }

  clear() {
    this.inputTarget.value = ""
    Array.from(this.selectTarget.options).forEach(o => { o.hidden = false })
  }
}
