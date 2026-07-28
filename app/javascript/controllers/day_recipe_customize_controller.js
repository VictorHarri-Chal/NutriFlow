import { Controller } from "@hotwired/stimulus"

// Ponctual, per-DayRecipe ingredient customization modal.
// Unlike modal_controller.js (fetched fresh via turbo_stream, discarded on close),
// this modal must survive open/close while holding live, possibly-unsaved nested
// form fields — so it toggles visibility instead of being removed from the DOM.
export default class extends Controller {
  static targets = [
    "modal", "panel", "title", "template", "itemsContainer",
    "recipeId", "quantityInput", "useRecipeQtyInput",
    "gearButton", "confirmButton"
  ]
  static values = { openOnConnect: Boolean }

  connect() {
    const dataEl = document.getElementById("recipes-data")
    this._recipes = dataEl ? JSON.parse(dataEl.textContent) : []
    this._snapshot = ""
    this._pristineState = "[]"

    this._boundRecipeChange = this._onRecipeChange.bind(this)
    this.recipeIdTarget.addEventListener("input", this._boundRecipeChange)

    this._updateGearButtonState()
    if (this.openOnConnectValue) this.open()
  }

  disconnect() {
    this.recipeIdTarget.removeEventListener("input", this._boundRecipeChange)
  }

  open() {
    this._snapshot = this.itemsContainerTarget.innerHTML

    // A fresh (still-empty) ingredient list means this DayRecipe hasn't been
    // seeded yet in the DOM — pre-fill it from the recipe, scaled by the
    // current base quantity, so the user edits from a sensible starting point.
    // Once there's at least one row (persisted items on edit, or a previous
    // seed/edit in this same session), leave it alone.
    if (this.itemsContainerTarget.children.length === 0) {
      this._seed(this._currentBaseQuantity())
    }

    // Valider stays disabled until the user actually changes something
    // relative to what's on screen right now (freshly seeded, or as loaded).
    this._pristineState = JSON.stringify(this._captureState())
    this._updateConfirmButtonState()

    this._updateTitle()
    this._syncEmptyState()
    this._syncRemoveButtons()

    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this._dispatchInput()
  }

  confirm(event) {
    event.preventDefault()
    if (this.confirmButtonTarget.disabled) return
    this._close()
  }

  cancel(event) {
    event.preventDefault()
    this.itemsContainerTarget.innerHTML = this._snapshot

    this._syncEmptyState()
    this._syncRemoveButtons()
    this._dispatchInput()
    this._close()
  }

  handleBackdropClick(event) {
    if (this.panelTarget.contains(event.target)) return
    this.cancel(event)
  }

  handleEscape(event) {
    if (event.key === "Escape" && !this.modalTarget.classList.contains("hidden")) this.cancel(event)
  }

  // Bound to the form's bubbling `input` event (quantity edits, unit changes,
  // add/remove rows).
  onFieldChange() {
    this._syncRemoveButtons()
    this._updateConfirmButtonState()
  }

  _onRecipeChange() {
    this._updateGearButtonState()

    // A quantity/toggle typed for the previous recipe means nothing for the
    // new one — reset back to the same default a brand new form starts with,
    // instead of silently carrying over a stale (but valid-looking) value.
    this.quantityInputTarget.value = ""
    this.useRecipeQtyInputTarget.checked = true

    if (this.itemsContainerTarget.children.length === 0) {
      this._dispatchInput()
      return
    }

    this.itemsContainerTarget.innerHTML = ""
    this._syncEmptyState()
    this._dispatchInput()
  }

  _close() {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  _updateGearButtonState() {
    // Editable when a recipe is selected (new entry) OR the log already has
    // materialized ingredients — including a detached log whose recipe was
    // deleted (recipe_id blank but frozen items are still there to adjust).
    const hasRecipe = (parseInt(this.recipeIdTarget.value) || 0) > 0
    const hasItems  = this.hasItemsContainerTarget && this.itemsContainerTarget.children.length > 0
    this.gearButtonTarget.disabled = !hasRecipe && !hasItems
  }

  _currentRecipe() {
    const id = parseInt(this.recipeIdTarget.value) || 0
    return this._recipes.find(r => r.id === id)
  }

  // The quantity/toggle inputs only exist on the "new" form (they're
  // meaningless once a DayRecipe is persisted — seeding only ever happens at
  // creation), so guard their absence here rather than assuming edit mode
  // never reaches this (e.g. every ingredient destroyed then a failed
  // resubmit reopens the modal on an empty, edit-mode itemsContainer).
  _currentBaseQuantity() {
    if (!this.hasQuantityInputTarget || !this.hasUseRecipeQtyInputTarget) return 0
    const recipe = this._currentRecipe()
    if (!recipe) return 0
    return this.useRecipeQtyInputTarget.checked ? recipe.totalWeight : (parseFloat(this.quantityInputTarget.value) || 0)
  }

  _updateTitle() {
    const recipe = this._currentRecipe()
    if (recipe) this.titleTarget.textContent = recipe.name
  }

  _seed(baseQuantity) {
    this.itemsContainerTarget.innerHTML = ""

    const recipe = this._currentRecipe()
    if (!recipe || !recipe.items || recipe.totalWeight <= 0 || baseQuantity <= 0) return

    const scale = baseQuantity / recipe.totalWeight

    // Purely numeric index: Rails' strong-parameter nested-attributes detection
    // requires digit-only hash keys, so a Date.now()-plus-random suffix (with an
    // underscore) gets rejected as "unpermitted". Multiplying by 1000 and adding
    // the loop index keeps every key unique without introducing non-digit chars.
    recipe.items.forEach((item, i) => {
      const uniqueIndex = Date.now() * 1000 + i
      const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, uniqueIndex)
      this.itemsContainerTarget.insertAdjacentHTML("beforeend", content)

      const row = this.itemsContainerTarget.lastElementChild
      row.querySelector('[data-role="food-id"]').value = item.foodId
      row.querySelector('[data-role="food-name"]').value = item.foodName
      row.querySelector('[data-role="quantity"]').value = (item.quantity * scale).toFixed(1)
      row.querySelector('[data-role="unit-hidden"]').value = item.unit
      row.querySelector('[data-role="unit-label"]').textContent = item.unit

      // The row's food-combobox controller connects with selectedIdValue still
      // at its template default (0) since we set the inputs directly instead of
      // going through its own select() — patch its backing data attribute too,
      // or it forgets a food is selected and clears the name on outside click.
      const combobox = row.querySelector('[data-controller="food-combobox"]')
      if (combobox) combobox.dataset.foodComboboxSelectedIdValue = item.foodId
    })
  }

  _dispatchInput() {
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
  }

  // _seed()/cancel() mutate itemsContainer directly (not via nested-form#add/#remove),
  // so nested-form's own updateEmptyState() never runs — keep its empty-state/add-button
  // visibility in sync here instead.
  _syncEmptyState() {
    const isEmpty = this.itemsContainerTarget.children.length === 0
    const emptyState = this.element.querySelector('[data-nested-form-target="emptyState"]')
    const addButton = this.element.querySelector('[data-nested-form-target="addButton"]')
    if (emptyState) emptyState.style.display = isEmpty ? "block" : "none"
    if (addButton) addButton.style.display = isEmpty ? "none" : "flex"
  }

  // At least one ingredient must always remain — disable the remove button on
  // the last visible row so the modal can never be confirmed/submitted empty.
  _syncRemoveButtons() {
    const rows = Array.from(this.itemsContainerTarget.querySelectorAll('[data-nested-form-target="item"]'))
      .filter(row => row.style.display !== "none")
    const onlyOne = rows.length <= 1
    rows.forEach(row => {
      const btn = row.querySelector('[data-role="remove-button"]')
      if (btn) btn.disabled = onlyOne
    })
  }

  _normalizeRow(foodId, quantity, unit) {
    return `${parseInt(foodId) || 0}:${(parseFloat(quantity) || 0).toFixed(2)}:${unit}`
  }

  _captureState() {
    return Array.from(this.itemsContainerTarget.querySelectorAll('[data-nested-form-target="item"]'))
      .filter(row => row.style.display !== "none")
      .map(row => this._normalizeRow(
        row.querySelector('[data-role="food-id"]')?.value,
        row.querySelector('[data-role="quantity"]')?.value,
        row.querySelector('[data-role="unit-hidden"]')?.value
      ))
      .sort()
  }

  _updateConfirmButtonState() {
    if (!this.hasConfirmButtonTarget) return
    this.confirmButtonTarget.disabled = JSON.stringify(this._captureState()) === this._pristineState
  }
}
