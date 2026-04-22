import { Controller } from "@hotwired/stimulus"

// Manages the workout session form:
// - receives "exercise-selected" from exercise-combobox, builds exercise groups
// - handles add/remove set per exercise
// - manages RPE slider ↔ hidden field sync
// - fetches "last performance" for context when an exercise is added
export default class extends Controller {
  static targets = ["exercisesList", "emptyHint", "noExerciseError", "noWeightError", "rpeSlider", "rpeDisplay", "rpeValue"]
  static values = {
    lastPerfPath:       String,
    exerciseSearchPath: String,
    labelWeight:        { type: String, default: "Poids (kg)" },
    labelReps:          { type: String, default: "Reps" },
    labelAddSet:        { type: String, default: "Série" },
    labelLastPerf:      { type: String, default: "Dernière fois" },
    labelMaxSets:       { type: String, default: "max 10" },
    noExerciseError:    { type: String, default: "Ajoutez au moins un exercice." }
  }

  connect() {
    this._setIndex = this._countExistingInputs()
    if (this.hasRpeSliderTarget && this.rpeSliderTarget.value) {
      this._syncRpeDisplay(this.rpeSliderTarget.value)
    }
    if (this.hasExercisesListTarget) {
      this._reindexPositions()
      this._syncEmptyHint()
      this.exercisesListTarget.querySelectorAll("[data-exercise-id]").forEach(group => {
        const container = group.querySelector(".sets-container")
        if (container) this._renumberSets(container)
      })
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
    if (!this.hasExercisesListTarget) return

    // Check exercises present
    const visible = this.exercisesListTarget.querySelectorAll("[data-exercise-id]:not(.hidden)")
    if (visible.length === 0) {
      event.preventDefault()
      if (this.hasNoExerciseErrorTarget) this.noExerciseErrorTarget.classList.remove("hidden")
      if (this.hasNoWeightErrorTarget)   this.noWeightErrorTarget.classList.add("hidden")
      return
    }
    if (this.hasNoExerciseErrorTarget) this.noExerciseErrorTarget.classList.add("hidden")

    // Check all visible weight and reps inputs are filled
    let missingField = false
    this.exercisesListTarget.querySelectorAll(".set-row:not(.hidden) input[name*='weight_kg']").forEach(input => {
      const empty = input.value === ""
      input.classList.toggle("input-weight-error", empty)
      if (empty) missingField = true
    })
    this.exercisesListTarget.querySelectorAll(".set-row:not(.hidden) input[name*='[reps]']").forEach(input => {
      const empty = input.value === ""
      input.classList.toggle("input-weight-error", empty)
      if (empty) missingField = true
    })

    // Check duration is filled
    const durationInput = this.element.querySelector("input[name='workout_session[duration_minutes]']")
    if (durationInput) {
      const empty = durationInput.value === ""
      durationInput.classList.toggle("input-weight-error", empty)
      if (empty) missingField = true
    }

    if (missingField) {
      event.preventDefault()
      if (this.hasNoWeightErrorTarget) this.noWeightErrorTarget.classList.remove("hidden")
      return
    }
    if (this.hasNoWeightErrorTarget) this.noWeightErrorTarget.classList.add("hidden")
  }

  // ── Exercise added from combobox ──────────────────────────────────

  addExercise(event) {
    if (event.type !== "exercise-selected") return
    const { id, name } = event.detail
    if (!id || !name) return

    // If the group exists but was soft-deleted (hidden), restore it instead of blocking
    const existing = this.element.querySelector(`[data-exercise-id="${id}"]`)
    if (existing) {
      if (!existing.classList.contains("hidden")) return
      existing.classList.remove("hidden")
      existing.querySelectorAll("[data-destroy-flag]").forEach(i => i.value = "0")
      existing.querySelectorAll(".set-row.hidden").forEach(r => r.classList.remove("hidden"))
      const container = existing.querySelector(".sets-container")
      if (container) this._renumberSets(container)
      this._syncEmptyHint()
      return
    }

    const group = this._buildExerciseGroup(id, name)
    this.exercisesListTarget.appendChild(group)
    this._syncEmptyHint()
    this._fetchLastPerformance(id, group)
  }

  // ── Set management ────────────────────────────────────────────────

  addSet(event) {
    const group     = event.currentTarget.closest("[data-exercise-id]")
    const container = group.querySelector(".sets-container")
    const visible   = container.querySelectorAll(".set-row:not(.hidden)")
    if (visible.length >= 10) return
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
    const group        = event.currentTarget.closest("[data-exercise-id]")
    const destroyFlags = group.querySelectorAll("[data-destroy-flag]")
    if (destroyFlags.length > 0) {
      destroyFlags.forEach(i => i.value = "1")
      group.classList.add("hidden")
    } else {
      group.remove()
    }
    this._syncEmptyHint()
  }

  // ── Private ───────────────────────────────────────────────────────

  _buildExerciseGroup(exerciseId, exerciseName) {
    const div = document.createElement("div")
    div.className = "exercise-group rounded-xl border border-surface-border/40 bg-surface-base p-3 space-y-2"
    div.dataset.exerciseId = exerciseId

    // Capture the index that will be used by the first _buildSetRow call
    const firstSetIdx = this._setIndex

    div.innerHTML = `
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm font-semibold text-ink-primary capitalize truncate exercise-name-label"></span>
        <button type="button" data-action="click->workout-form#removeExercise"
                class="text-xs text-ink-subtle hover:text-status-danger transition-colors cursor-pointer shrink-0">
          <i class="fas fa-times"></i>
        </button>
      </div>
      <div class="last-perf hidden rounded-lg bg-surface-hover border border-surface-border/30 px-3 py-1.5 flex items-center gap-2">
        <i class="fas fa-history text-[10px] text-ink-subtle shrink-0"></i>
        <span class="last-perf-text text-xs text-ink-subtle flex-1"></span>
        <span class="last-perf-delta hidden text-[10px] font-semibold shrink-0"></span>
      </div>
      <div class="grid grid-cols-[16px_1fr_1fr_20px] gap-2 text-xs text-ink-subtle">
        <span>#</span>
        <span>${this.labelWeightValue}</span>
        <span>${this.labelRepsValue}</span>
        <span></span>
      </div>
      <div class="sets-container space-y-1.5"></div>
      <div class="flex items-center gap-2 mt-1">
        <button type="button" data-action="click->workout-form#addSet"
                class="text-xs text-brand hover:text-brand/80 transition-colors flex items-center gap-1 cursor-pointer">
          <i class="fas fa-plus text-[10px]"></i>
          ${this.labelAddSetValue}
        </button>
        <span class="hidden text-[10px] text-ink-subtle/40" data-add-set-max-hint>${this.labelMaxSetsValue}</span>
      </div>
      <div class="space-y-1 border-t border-surface-border/20 pt-2 mt-1">
        <div class="flex items-center gap-1.5">
          <i class="fas fa-hourglass-half text-[9px] text-ink-subtle/40 shrink-0 w-3 text-center"></i>
          <div class="relative flex-1">
            <input type="number"
                   name="workout_session[workout_sets_attributes][${firstSetIdx}][rest_seconds]"
                   min="0" step="5"
                   class="w-full pr-7 text-[11px] bg-transparent border border-transparent rounded px-1 py-0.5 text-ink-muted placeholder:text-ink-subtle/30 hover:border-surface-border/50 focus:border-brand/40 focus:outline-none focus:bg-surface-hover transition-colors cursor-text">
            <span class="absolute right-1.5 top-1/2 -translate-y-1/2 text-[9px] text-ink-subtle/30 pointer-events-none">sec</span>
          </div>
        </div>
        <div class="flex items-start gap-1.5">
          <i class="fas fa-comment-alt text-[9px] text-ink-subtle/40 shrink-0 w-3 text-center mt-1.5"></i>
          <textarea name="workout_session[workout_sets_attributes][${firstSetIdx}][notes]"
                    rows="1"
                    style="resize: none; overflow-y: hidden;"
                    class="w-full text-[11px] bg-transparent border border-transparent rounded px-1 py-0.5 text-ink-muted placeholder:text-ink-subtle/30 hover:border-surface-border/50 focus:border-brand/40 focus:outline-none focus:bg-surface-hover transition-all cursor-text min-h-[20px] focus:min-h-[48px]"></textarea>
        </div>
      </div>
    `
    div.querySelector(".exercise-name-label").textContent = exerciseName

    const container = div.querySelector(".sets-container")
    for (let i = 0; i < 3; i++) container.appendChild(this._buildSetRow(exerciseId))
    this._renumberSets(container)
    return div
  }

  _buildSetRow(exerciseId, opts = {}) {
    const idx = this._setIndex++
    const div = document.createElement("div")
    div.className = "set-row"

    div.innerHTML = `
      <input type="hidden" name="workout_session[workout_sets_attributes][${idx}][exercise_id]" value="${exerciseId}">
      <input type="hidden" name="workout_session[workout_sets_attributes][${idx}][position]" value="0" data-position-input="true">
      <div class="grid grid-cols-[16px_1fr_1fr_20px] gap-2 items-center">
        <span class="text-xs text-ink-subtle set-number"></span>
        <input type="number" name="workout_session[workout_sets_attributes][${idx}][weight_kg]"
               placeholder="0" min="0" step="0.5" value="${opts.weightKg != null ? opts.weightKg : ''}"
               class="input-dark text-sm py-1.5 cursor-text">
        <input type="number" name="workout_session[workout_sets_attributes][${idx}][reps]"
               value="${opts.reps != null ? opts.reps : 10}" min="0" step="1"
               class="input-dark text-sm py-1.5 cursor-text">
        <button type="button" data-action="click->workout-form#removeSet"
                class="text-ink-subtle hover:text-status-danger transition-colors text-xs flex items-center justify-center cursor-pointer">
          <i class="fas fa-times"></i>
        </button>
      </div>
    `
    return div
  }

  _renumberSets(container) {
    const rows = Array.from(container.querySelectorAll(".set-row:not(.hidden)"))
    rows.forEach((row, i) => {
      const num = row.querySelector(".set-number")
      if (num) num.textContent = i + 1
      const btn = row.querySelector("[data-action*='removeSet']")
      if (btn) {
        btn.classList.toggle("invisible",           i === 0)
        btn.classList.toggle("pointer-events-none", i === 0)
      }
    })
    const group  = container.closest("[data-exercise-id]")
    const addBtn = group?.querySelector("[data-action*='addSet']")
    if (addBtn) {
      const atMax = rows.length >= 10
      addBtn.classList.toggle("opacity-30",          atMax)
      addBtn.classList.toggle("pointer-events-none", atMax)
      const maxHint = group.querySelector("[data-add-set-max-hint]")
      if (maxHint) maxHint.classList.toggle("hidden", !atMax)
    }
    this._reindexPositions()
  }

  _reindexPositions() {
    if (!this.hasExercisesListTarget) return
    let pos = 0
    Array.from(this.exercisesListTarget.querySelectorAll(".set-row:not(.hidden)")).forEach(row => {
      const posInput = row.querySelector("[data-position-input]")
      if (posInput) posInput.value = pos++
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

      // Delta vs previous session (only for weighted exercises)
      const deltaEl = group.querySelector(".last-perf-delta")
      if (deltaEl && data.delta != null && data.delta !== 0) {
        const sign = data.delta > 0 ? "+" : ""
        deltaEl.textContent = `${sign}${data.delta}kg`
        deltaEl.className = [
          "last-perf-delta text-[10px] font-semibold shrink-0",
          data.delta > 0 ? "text-status-success" : "text-ink-subtle/50"
        ].join(" ")
        deltaEl.classList.remove("hidden")
      }
    } catch (_) {}
  }
}
