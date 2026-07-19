import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["registry", "select", "value", "unit", "list"]

  connect() {
    this._registry = JSON.parse(this.registryTarget.textContent)
    this._hiddenField = this.element.closest("form")
      .querySelector('[data-food-off-search-target="micronutrientsField"]')
    this._renderExisting()
    this.syncUnit()
  }

  syncUnit() {
    const entry = this._entry(this.selectTarget.value)
    if (this.hasUnitTarget) this.unitTarget.textContent = entry ? entry.unit : ""
  }

  add(event) {
    event.preventDefault()
    const key   = this.selectTarget.value
    const value = parseFloat(this.valueTarget.value)
    if (!key || isNaN(value) || value <= 0) return

    const data = this._currentData()
    data[key] = value
    this._persist(data)
    this._removeOption(key)
    this._appendRow(key, value)
    this.valueTarget.value = ""
    this.syncUnit()
  }

  remove(event) {
    const key  = event.currentTarget.dataset.key
    const data = this._currentData()
    delete data[key]
    this._persist(data)
    this._restoreOption(key)
    event.currentTarget.closest("[data-key-row]").remove()
  }

  _currentData() {
    if (!this._hiddenField) return {}
    try {
      return JSON.parse(this._hiddenField.value || "{}")
    } catch {
      return {}
    }
  }

  _persist(data) {
    if (this._hiddenField) this._hiddenField.value = JSON.stringify(data)
  }

  _renderExisting() {
    Object.entries(this._currentData()).forEach(([key, value]) => {
      this._removeOption(key)
      this._appendRow(key, value)
    })
  }

  _entry(key) {
    return this._registry.find(e => e.key === key)
  }

  _appendRow(key, value) {
    const entry = this._entry(key)
    if (!entry) return
    const row = document.createElement("div")
    row.dataset.keyRow = key
    row.className = "flex items-center justify-between py-2"
    row.innerHTML = `
      <span class="text-xs text-ink-muted">${entry.label}</span>
      <div class="flex items-center gap-3">
        <span class="text-xs font-semibold text-ink-primary">${value} ${entry.unit}</span>
        <i class="fas fa-times text-ink-subtle text-xs cursor-pointer hover:text-status-danger"
           data-action="click->micronutrient-editor#remove" data-key="${key}"></i>
      </div>
    `
    this.listTarget.appendChild(row)
  }

  _removeOption(key) {
    const option = Array.from(this.selectTarget.options).find(o => o.value === key)
    if (option) option.remove()
    this._rebuildCustomSelect()
  }

  _restoreOption(key) {
    const entry = this._entry(key)
    if (!entry) return
    const option = document.createElement("option")
    option.value = key
    option.text  = entry.label
    this.selectTarget.appendChild(option)
    this._rebuildCustomSelect()
  }

  _rebuildCustomSelect() {
    const wrapper = this.selectTarget.closest('[data-controller~="custom-select"]')
    if (!wrapper) return
    wrapper.removeAttribute("data-controller")
    requestAnimationFrame(() => wrapper.setAttribute("data-controller", "custom-select"))
    if (this.selectTarget.options.length > 0) this.selectTarget.selectedIndex = 0
    this.syncUnit()
  }
}
