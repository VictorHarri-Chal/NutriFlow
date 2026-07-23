import { Controller } from "@hotwired/stimulus"

const SECONDS_PER_REP = 3 // mirrors DurationEstimatable::SECONDS_PER_REP (app/models/concerns/duration_estimatable.rb)
const MINIMUM_MINUTES = 1 // mirrors DurationEstimatable::MINIMUM_MINUTES (app/models/concerns/duration_estimatable.rb)

// Mirrors SetTypesHelper#set_type_pill_classes (size: :md) — Tailwind classes must
// appear as literal strings for the JIT scanner to pick them up, so this is duplicated
// here rather than fetched from the server (same tradeoff as the rest of this file's
// JS-built markup, which already duplicates the ERB templates).
const SET_TYPE_PILL_BASE_CLASSES = "inline-flex items-center px-3 py-1.5 rounded-full text-[10px] font-medium border cursor-pointer transition-colors bg-surface-hover text-ink-muted border-surface-border/40"
const SET_TYPE_PILL_CLASSES = {
  warmup:  `${SET_TYPE_PILL_BASE_CLASSES} peer-checked/warmup:bg-status-success/20 peer-checked/warmup:text-status-success peer-checked/warmup:border-status-success/50`,
  working: `${SET_TYPE_PILL_BASE_CLASSES} peer-checked/working:bg-brand/20 peer-checked/working:text-brand peer-checked/working:border-brand/50`,
  failure: `${SET_TYPE_PILL_BASE_CLASSES} peer-checked/failure:bg-status-danger/20 peer-checked/failure:text-status-danger peer-checked/failure:border-status-danger/50`,
  dropset: `${SET_TYPE_PILL_BASE_CLASSES} peer-checked/dropset:bg-status-info/20 peer-checked/dropset:text-status-info peer-checked/dropset:border-status-info/50`
}

// Manages the workout session form:
// - receives "exercise-selected" from exercise-combobox, builds exercise groups
// - handles add/remove set per exercise
// - fetches "last performance" for context when an exercise is added
export default class extends Controller {
  static targets = ["exercisesList", "emptyHint", "noExerciseError", "noWeightError", "durationInput", "durationHint", "durationEstimate"]
  static values = {
    lastPerfPath:       String,
    exerciseSearchPath: String,
    labelWeight:        { type: String, default: "Poids (kg)" },
    labelReps:          { type: String, default: "Reps" },
    labelRpe:           { type: String, default: "RPE" },
    rpeOptions:         { type: Array, default: [] },
    labelAddSet:        { type: String, default: "Série" },
    labelRestPlaceholder:  { type: String, default: "Repos entre séries" },
    labelNotesPlaceholder: { type: String, default: "Notes de l'exercice" },
    labelSetTypeToggle:    { type: String, default: "Type de série" },
    labelLastPerf:      { type: String, default: "Dernière perf" },
    labelMaxSets:       { type: String, default: "max 10" },
    noExerciseError:    { type: String, default: "Ajoutez au moins un exercice." },
    sessionId:          { type: Number, default: 0 },
    sessionDate:        { type: String, default: "" },
    infoTooltip:            { type: String, default: "" },
    labelSetTypeWarmup:     { type: String, default: "Échauffement" },
    labelSetTypeWorking:    { type: String, default: "Travail" },
    labelSetTypeFailure:    { type: String, default: "Dead set" },
    labelSetTypeDropset:    { type: String, default: "Drop-set" }
  }

  connect() {
    this._setIndex    = this._countExistingInputs()
    this._allTimeMaxes = new Map() // exerciseId → all-time max weight (for PR detection)
    if (this.hasExercisesListTarget) {
      this._reindexPositions()
      this._syncEmptyHint()
      this.exercisesListTarget.querySelectorAll("[data-exercise-id]").forEach(group => {
        const container = group.querySelector(".sets-container")
        if (container) this._renumberSets(container)
        // Fetch last perf for exercises already in form (edit mode)
        const exerciseId = group.dataset.exerciseId
        if (exerciseId) this._fetchLastPerformance(exerciseId, group)
      })
    }
    this.recalculateDuration()
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
      this._recomputeGroupPrBadges(existing)
      this.recalculateDuration()
      return
    }

    const group = this._buildExerciseGroup(id, name)
    this.exercisesListTarget.appendChild(group)
    this._syncEmptyHint()
    this._fetchLastPerformance(id, group)
    this.recalculateDuration()
  }

  // ── Set management ────────────────────────────────────────────────

  addSet(event) {
    const group     = event.currentTarget.closest("[data-exercise-id]")
    const container = group.querySelector(".sets-container")
    const visible   = container.querySelectorAll(".set-row:not(.hidden)")
    if (visible.length >= 10) return
    container.appendChild(this._buildSetRow(group.dataset.exerciseId))
    this._renumberSets(container)
    this.recalculateDuration()
  }

  removeSet(event) {
    const row          = event.currentTarget.closest(".set-row")
    // Captured before any removal: row.remove() detaches row from its parent,
    // which would make a closest() lookup from a descendant fail afterward.
    const container    = row.closest(".sets-container")
    const group        = row.closest("[data-exercise-id]")
    const destroyInput = row.querySelector("[data-destroy-flag]")
    if (destroyInput) {
      destroyInput.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
    if (container) this._renumberSets(container)
    if (group) this._recomputeGroupPrBadges(group)
    this.recalculateDuration()
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
    this.recalculateDuration()
  }

  // ── PR detection ─────────────────────────────────────────────────

  checkPr(event) {
    const group = event.currentTarget.closest("[data-exercise-id]")
    if (group) this._recomputeGroupPrBadges(group)
  }

  // Mirrors PrRecalculator's server-side sweep: walk this exercise's sets in
  // position order starting from the historical baseline (all_time_max,
  // possibly 0 for a brand-new exercise), so a badge only lights up once a
  // set strictly beats the best weight logged before it — including earlier
  // sets typed in this same session, not just the fetched baseline in
  // isolation. Re-run on every weight edit, and on any change to which rows
  // are active (add/remove/restore), so the whole sequence stays consistent.
  _recomputeGroupPrBadges(group) {
    const exerciseId = group.dataset.exerciseId
    if (!this._allTimeMaxes.has(exerciseId)) return // baseline not loaded yet

    let runningMax = this._allTimeMaxes.get(exerciseId)
    group.querySelectorAll(".set-row:not(.hidden)").forEach(row => {
      const input = row.querySelector("[name*='weight_kg']")
      const badge = row.querySelector("[data-pr-badge]")
      if (!input || !badge) return
      const val = parseFloat(input.value)
      const isPr = val > 0 && runningMax > 0 && val > runningMax
      badge.classList.toggle("hidden", !isPr)
      if (val > runningMax) runningMax = val
    })
  }

  // ── Duration estimate ─────────────────────────────────────────────
  // The duration field stays fully user-controlled. We only compute an
  // estimate (reps × 3s + rest per set, floored at 1 min) and surface it in
  // a call-out with a "use" button — shown only when it differs from the
  // current input value, mirroring the profile's water-goal estimator.

  recalculateDuration() {
    if (!this.hasDurationInputTarget || !this.hasExercisesListTarget) return

    const groups = this.exercisesListTarget.querySelectorAll(".exercise-group:not(.hidden)")
    if (groups.length === 0) {
      this._durationEstimate = null
      if (this.hasDurationHintTarget) this.durationHintTarget.classList.add("hidden")
      return
    }

    let totalSeconds = 0
    groups.forEach(group => {
      const repsInputs = group.querySelectorAll(".set-row:not(.hidden) input[name*='[reps]']")
      repsInputs.forEach(input => {
        totalSeconds += (parseInt(input.value, 10) || 0) * SECONDS_PER_REP
      })
      const restInput = group.querySelector("input[name*='[rest_seconds]']")
      if (restInput) totalSeconds += (parseInt(restInput.value, 10) || 0) * repsInputs.length
    })
    this._durationEstimate = Math.max(MINIMUM_MINUTES, Math.round(totalSeconds / 60))
    this._syncDurationHint()
  }

  useDuration() {
    if (this._durationEstimate == null) return
    this.durationInputTarget.value = this._durationEstimate
    if (this.hasDurationHintTarget) this.durationHintTarget.classList.add("hidden")
  }

  _syncDurationHint() {
    if (!this.hasDurationHintTarget) return
    const current = parseInt(this.durationInputTarget.value, 10) || 0
    if (this._durationEstimate == null || this._durationEstimate === current) {
      this.durationHintTarget.classList.add("hidden")
    } else {
      if (this.hasDurationEstimateTarget) this.durationEstimateTarget.textContent = `${this._durationEstimate} min`
      this.durationHintTarget.classList.remove("hidden")
    }
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
        <div class="flex items-center gap-1.5 min-w-0">
          <span class="text-sm font-semibold text-ink-primary capitalize truncate exercise-name-label"></span>
          <i class="fas fa-circle-info text-xs text-ink-subtle/40 hover:text-ink-subtle cursor-default transition-colors shrink-0"
             title="${this.infoTooltipValue}"></i>
        </div>
        <button type="button" data-action="click->workout-form#removeExercise"
                class="text-xs text-ink-subtle hover:text-status-danger transition-colors cursor-pointer shrink-0">
          <i class="fas fa-times"></i>
        </button>
      </div>
      <div class="grid grid-cols-[16px_1fr_1fr_1fr_28px_20px] gap-2 text-[9px] font-medium uppercase tracking-wider text-ink-subtle/60">
        <span>#</span>
        <span>${this.labelRepsValue}</span>
        <span>${this.labelWeightValue}</span>
        <span>${this.labelRpeValue}</span>
        <span></span>
        <span></span>
      </div>
      <div class="sets-container divide-y divide-surface-border/20"></div>
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
          <i class="fas fa-hourglass-half text-[9px] text-ink-subtle/70 shrink-0 w-3 text-center"></i>
          <div class="relative flex-1">
            <input type="number"
                   name="workout_session[workout_sets_attributes][${firstSetIdx}][rest_seconds]"
                   min="0" step="5"
                   placeholder="${this.labelRestPlaceholderValue}"
                   data-controller="digit-limit"
                   data-action="input->digit-limit#limit input->workout-form#recalculateDuration"
                   data-digit-limit-max-integer-digits-value="4"
                   class="w-full pr-7 text-[11px] bg-transparent border border-transparent rounded px-1 py-0.5 text-ink-muted placeholder:text-ink-subtle/50 hover:border-surface-border/50 focus:border-brand/40 focus:outline-none focus:bg-surface-hover transition-colors cursor-text">
            <span class="absolute right-1.5 top-1/2 -translate-y-1/2 text-[9px] text-ink-subtle/30 pointer-events-none">sec</span>
          </div>
        </div>
        <div class="flex items-start gap-1.5">
          <i class="fas fa-comment-alt text-[9px] text-ink-subtle/70 shrink-0 w-3 text-center mt-1.5"></i>
          <textarea name="workout_session[workout_sets_attributes][${firstSetIdx}][notes]"
                    rows="1"
                    placeholder="${this.labelNotesPlaceholderValue}"
                    style="resize: none; overflow-y: hidden;"
                    class="w-full text-[11px] bg-transparent border border-transparent rounded px-1 py-0.5 text-ink-muted placeholder:text-ink-subtle/50 hover:border-surface-border/50 focus:border-brand/40 focus:outline-none focus:bg-surface-hover transition-all cursor-text min-h-[20px] focus:min-h-[48px]"></textarea>
        </div>
      </div>
      <div class="last-perf hidden rounded-lg bg-surface-hover border border-surface-border/30 px-3 py-1.5 flex items-center gap-2">
        <i class="fas fa-history text-[10px] text-ink-subtle shrink-0"></i>
        <span class="last-perf-text text-xs text-ink-subtle flex-1"></span>
        <span class="last-perf-delta hidden text-[10px] font-semibold shrink-0"></span>
      </div>
    `
    div.querySelector(".exercise-name-label").textContent = exerciseName

    const container = div.querySelector(".sets-container")
    container.appendChild(this._buildSetRow(exerciseId))
    this._renumberSets(container)
    return div
  }

  _buildSetRow(exerciseId, opts = {}) {
    const idx = this._setIndex++
    const div = document.createElement("div")
    div.className = "set-row py-2"

    div.innerHTML = `
      <input type="hidden" name="workout_session[workout_sets_attributes][${idx}][exercise_id]" value="${exerciseId}">
      <input type="hidden" name="workout_session[workout_sets_attributes][${idx}][position]" value="0" data-position-input="true">
      <div class="grid grid-cols-[16px_1fr_1fr_1fr_28px_20px] gap-2 items-center">
        <span class="text-xs text-ink-subtle set-number"></span>
        <input type="number" name="workout_session[workout_sets_attributes][${idx}][reps]"
               value="${opts.reps != null ? opts.reps : ''}" min="1" step="1"
               data-controller="digit-limit"
               data-action="input->digit-limit#limit input->workout-form#recalculateDuration"
               data-digit-limit-max-integer-digits-value="4"
               class="input-dark text-sm py-1.5 cursor-text">
        <input type="number" name="workout_session[workout_sets_attributes][${idx}][weight_kg]"
               data-controller="digit-limit"
               data-action="input->workout-form#checkPr input->digit-limit#limit"
               data-digit-limit-max-integer-digits-value="4"
               data-digit-limit-max-decimal-digits-value="1"
               min="0" step="0.5" value="${opts.weightKg != null ? opts.weightKg : ''}"
               class="input-dark text-sm py-1.5 cursor-text">
        <div data-controller="custom-select" class="relative min-w-0">
          <select name="workout_session[workout_sets_attributes][${idx}][rpe]" class="sr-only" data-custom-select-target="select">
            <option value="">—</option>
            ${this.rpeOptionsValue.map(([label, value]) => `<option value="${value}">${label}</option>`).join("")}
          </select>
          <button type="button" data-action="click->custom-select#toggle"
                  class="input-dark text-sm py-1.5 px-1 cursor-pointer w-full flex items-center justify-center">
            <span data-custom-select-target="label" class="text-ink-subtle truncate min-w-0"></span>
          </button>
          <div data-custom-select-target="dropdown"
               class="hidden absolute z-50 w-56 right-0 mt-1 bg-surface-raised border border-surface-border/60 rounded-lg shadow-2xl max-h-52 overflow-y-auto"></div>
        </div>
        <span data-pr-badge
              class="hidden flex items-center justify-center text-[9px] font-bold text-brand bg-brand/10 border border-brand/30 rounded px-1.5 py-0.5 leading-none whitespace-nowrap">
          PR
        </span>
        <button type="button" data-action="click->workout-form#removeSet"
                class="text-ink-subtle hover:text-status-danger transition-colors text-xs flex items-center justify-center cursor-pointer">
          <i class="fas fa-times"></i>
        </button>
      </div>

      <div class="flex flex-wrap gap-2 pl-6 mt-1.5">
        ${this._buildSetTypePills(idx)}
      </div>
    `
    return div
  }

  _buildSetTypePills(idx) {
    const types = [
      { key: "warmup",  label: this.labelSetTypeWarmupValue },
      { key: "working", label: this.labelSetTypeWorkingValue },
      { key: "failure", label: this.labelSetTypeFailureValue },
      { key: "dropset", label: this.labelSetTypeDropsetValue }
    ]
    const pills = types.map(({ key, label }) => {
      const checkboxId = `workout_set_${idx}_set_types_${key}`
      const checked    = key === "working" ? "checked" : ""
      return `
        <input type="checkbox" name="workout_session[workout_sets_attributes][${idx}][set_types][]" value="${key}" ${checked}
               id="${checkboxId}" class="hidden peer/${key}">
        <label for="${checkboxId}" class="${SET_TYPE_PILL_CLASSES[key]}">${label}</label>
      `
    }).join("")
    return `${pills}<input type="hidden" name="workout_session[workout_sets_attributes][${idx}][set_types][]" value="">`
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

  // Starting index for JS-added sets. Existing rows use either a real
  // WorkoutSet id or a server-generated placeholder (see _form.html.erb),
  // so the full millisecond timestamp (not truncated) keeps new keys out
  // of reach of any real database id, avoiding a nested-attributes key
  // collision — same convention as nested_form_controller.js's NEW_RECORD.
  _countExistingInputs() {
    const existing = this.element.querySelectorAll("[name*='workout_sets_attributes']")
    return existing.length > 0 ? Date.now() : 0
  }

  _syncEmptyHint() {
    if (!this.hasEmptyHintTarget) return
    const hasGroups = this.exercisesListTarget.querySelector("[data-exercise-id]:not(.hidden)")
    this.emptyHintTarget.classList.toggle("hidden", !!hasGroups)
  }

  async _fetchLastPerformance(exerciseId, group) {
    let path = this.lastPerfPathValue.replace(":id", exerciseId)
    const params = new URLSearchParams()
    if (this.sessionIdValue > 0) params.set("exclude_session_id", this.sessionIdValue)
    if (this.sessionDateValue)   params.set("as_of_date", this.sessionDateValue)
    if ([...params].length) path += `?${params.toString()}`
    try {
      const res  = await fetch(path, { headers: { Accept: "application/json" } })
      if (!res.ok) return
      const data = await res.json()

      // Store the historical baseline — even when it's 0 (a brand-new
      // exercise still needs a known baseline so a later, heavier set typed
      // in this same session can be recognized as a PR) — then re-evaluate
      // every set in the group as one chronological sequence.
      this._allTimeMaxes.set(exerciseId, data.all_time_max || 0)
      this._recomputeGroupPrBadges(group)

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

      // Delta with directional arrow + red for regressions
      const deltaEl = group.querySelector(".last-perf-delta")
      if (deltaEl && data.delta != null && data.delta !== 0) {
        const isPositive = data.delta > 0
        deltaEl.textContent = isPositive ? `↑ +${data.delta}kg` : `↓ ${data.delta}kg`
        deltaEl.className = [
          "last-perf-delta text-[10px] font-semibold shrink-0",
          isPositive ? "text-status-success" : "text-status-danger"
        ].join(" ")
        deltaEl.classList.remove("hidden")
      }
    } catch (_) {}
  }
}
