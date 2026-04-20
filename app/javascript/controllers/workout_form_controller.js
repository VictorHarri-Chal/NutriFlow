import { Controller } from "@hotwired/stimulus"

// Manages the workout session form:
// - receives "exercise-selected" from exercise-combobox, builds exercise groups
// - handles add/remove set per exercise
// - manages RPE slider ↔ hidden field sync
// - fetches "last performance" for context when an exercise is added
export default class extends Controller {
  static targets = ["exercisesList", "emptyHint", "noExerciseError", "rpeSlider", "rpeDisplay", "rpeValue"]
  static values = {
    lastPerfPath:       String,
    labelWeight:        { type: String, default: "Poids (kg)" },
    labelReps:          { type: String, default: "Reps" },
    labelAddSet:        { type: String, default: "Série" },
    labelLastPerf:      { type: String, default: "Dernière fois" },
    noExerciseError:    { type: String, default: "Ajoutez au moins un exercice." }
  }

  connect() {
    this._setIndex = this._countExistingInputs()
    // Sync RPE display on load (edit form)
    if (this.hasRpeSliderTarget && this.rpeSliderTarget.value) {
      this._syncRpeDisplay(this.rpeSliderTarget.value)
    }
  }

  // ── RPE slider ────────────────────────────────────────────────────

  updateRpe(event) {
    const val = event.currentTarget.value
    this._syncRpeDisplay(val)
    if (this.hasRpeValueTarget) this.rpeValueTarget.value = val
  }

  _syncRpeDisplay(val) {
    if (!this.hasRpeDisplayTarget) return
    if (!val) { this.rpeDisplayTarget.textContent = "—"; return }
    this.rpeDisplayTarget.textContent = `${val}/10`
  }

  // ── Form submit validation ────────────────────────────────────────

  validateSubmit(event) {
    const visible = this.exercisesListTarget.querySelectorAll("[data-exercise-id]:not(.hidden)")
    if (visible.length === 0) {
      event.preventDefault()
      if (this.hasNoExerciseErrorTarget) {
        this.noExerciseErrorTarget.classList.remove("hidden")
      }
    } else {
      if (this.hasNoExerciseErrorTarget) {
        this.noExerciseErrorTarget.classList.add("hidden")
      }
    }
  }

  // ── Exercise added from combobox ──────────────────────────────────

  addExercise(event) {
    // Only handle custom events from exercise-combobox
    if (event.type !== "exercise-selected") return

    const { id, name } = event.detail
    if (!id || !name) return

    // Don't add duplicate
    if (this.element.querySelector(`[data-exercise-id="${id}"]`)) return

    const group = this._buildExerciseGroup(id, name)
    this.exercisesListTarget.appendChild(group)
    this._syncEmptyHint()
    this._fetchLastPerformance(id, group)
  }

  // ── Set management ────────────────────────────────────────────────

  addSet(event) {
    const group     = event.currentTarget.closest("[data-exercise-id]")
    const container = group.querySelector(".sets-container")
    container.appendChild(this._buildSetRow(group.dataset.exerciseId))
    this._renumberSets(container)
  }

  removeSet(event) {
    const row          = event.currentTarget.closest(".set-row")
    const destroyInput = row.querySelector("[data-destroy-flag]")
    if (destroyInput) {
      destroyInput.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
    const container = event.currentTarget.closest(".sets-container")
    if (container) this._renumberSets(container)
  }

  removeExercise(event) {
    const group = event.currentTarget.closest("[data-exercise-id]")
    const destroyFlags = group.querySelectorAll("[data-destroy-flag]")
    if (destroyFlags.length > 0) {
      // Persisted sets — mark for destruction and hide, keep inputs in DOM so they submit
      destroyFlags.forEach(i => i.value = "1")
      group.classList.add("hidden")
    } else {
      // Newly added group (no persisted sets) — safe to remove from DOM entirely
      group.remove()
    }
    this._syncEmptyHint()
  }

  // ── Private ───────────────────────────────────────────────────────

  _buildExerciseGroup(exerciseId, exerciseName) {
    const div = document.createElement("div")
    div.className = "exercise-group rounded-xl border border-surface-border/40 bg-surface-base p-3 space-y-2"
    div.dataset.exerciseId = exerciseId

    div.innerHTML = `
      <div class="flex items-center justify-between">
        <span class="text-sm font-semibold text-ink-primary capitalize exercise-name-label"></span>
        <button type="button" data-action="click->workout-form#removeExercise"
                class="text-xs text-ink-subtle hover:text-status-danger transition-colors cursor-pointer">
          <i class="fas fa-times"></i>
        </button>
      </div>
      <div class="last-perf hidden rounded-lg bg-surface-hover border border-surface-border/30 px-3 py-1.5 flex items-center gap-2">
        <i class="fas fa-history text-[10px] text-ink-subtle shrink-0"></i>
        <span class="last-perf-text text-xs text-ink-subtle"></span>
      </div>
      <div class="grid grid-cols-12 gap-2 text-xs text-ink-subtle">
        <span class="col-span-1">#</span>
        <span class="col-span-5">${this.labelWeightValue}</span>
        <span class="col-span-5">${this.labelRepsValue}</span>
        <span class="col-span-1"></span>
      </div>
      <div class="sets-container space-y-1.5"></div>
      <button type="button" data-action="click->workout-form#addSet"
              class="text-xs text-brand hover:text-brand/80 transition-colors flex items-center gap-1 cursor-pointer mt-1">
        <i class="fas fa-plus text-[10px]"></i>
        ${this.labelAddSetValue}
      </button>
    `
    div.querySelector(".exercise-name-label").textContent = exerciseName

    const container = div.querySelector(".sets-container")
    container.appendChild(this._buildSetRow(exerciseId))
    this._renumberSets(container)
    return div
  }

  _buildSetRow(exerciseId) {
    const idx = this._setIndex++
    const div = document.createElement("div")
    div.className = "set-row grid grid-cols-12 gap-2 items-center"
    div.innerHTML = `
      <input type="hidden"
             name="workout_session[workout_sets_attributes][${idx}][exercise_id]"
             value="${exerciseId}">
      <span class="col-span-1 text-xs text-ink-subtle set-number"></span>
      <input type="number"
             name="workout_session[workout_sets_attributes][${idx}][weight_kg]"
             placeholder="0" min="0" step="0.5"
             class="col-span-5 input-dark text-sm py-1.5 cursor-text">
      <input type="number"
             name="workout_session[workout_sets_attributes][${idx}][reps]"
             value="12" min="0" step="1"
             class="col-span-5 input-dark text-sm py-1.5 cursor-text">
      <button type="button" data-action="click->workout-form#removeSet"
              class="col-span-1 text-ink-subtle hover:text-status-danger transition-colors text-xs flex items-center justify-center cursor-pointer">
        <i class="fas fa-times"></i>
      </button>
    `
    return div
  }

  _renumberSets(container) {
    Array.from(container.querySelectorAll(".set-row:not(.hidden)"))
      .forEach((row, i) => {
        const num = row.querySelector(".set-number")
        if (num) num.textContent = i + 1
        // First visible set is mandatory — hide its × button
        const btn = row.querySelector("[data-action*='removeSet']")
        if (btn) {
          btn.classList.toggle("invisible",        i === 0)
          btn.classList.toggle("pointer-events-none", i === 0)
        }
      })
  }

  _countExistingInputs() {
    const existing = this.element.querySelectorAll("[name*='workout_sets_attributes']")
    return existing.length > 0 ? Date.now() % 100000 : 0
  }

  _syncEmptyHint() {
    if (!this.hasEmptyHintTarget) return
    const hasGroups = this.exercisesListTarget.querySelector("[data-exercise-id]:not(.hidden)")
    this.emptyHintTarget.classList.toggle("hidden", !!hasGroups)
  }

  async _fetchLastPerformance(exerciseId, group) {
    const path = this.lastPerfPathValue.replace(":id", exerciseId)
    try {
      const res  = await fetch(path, { headers: { Accept: "application/json" } })
      if (!res.ok) return
      const data = await res.json()
      if (!data.sets?.length) return

      const parts = data.sets.map(s => {
        const w = (s.weight_kg && s.weight_kg > 0) ? `${s.weight_kg}kg` : "PDC"
        return `${w} × ${s.reps}`
      }).join("  ·  ")

      const lastPerf = group.querySelector(".last-perf")
      const text     = group.querySelector(".last-perf-text")
      if (lastPerf && text) {
        text.textContent = `${this.labelLastPerfValue} (${data.date}) : ${parts}`
        lastPerf.classList.remove("hidden")
      }
    } catch (_) {}
  }
}
