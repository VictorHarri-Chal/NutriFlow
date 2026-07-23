// Rendu partagé des badges Nutri-Score/NOVA/Eco-Score et des chips
// allergènes/traces/additifs/labels — utilisé par food_off_search_controller.js
// (page /foods/new) et scan_result_controller.js (modale de scan), pour éviter
// de dupliquer les couleurs officielles OFF et la construction des chips.
export const NS_COLORS   = { a: "#038141", b: "#85BB2F", c: "#FECB02", d: "#EE8100", e: "#E63E11" }
export const NOVA_COLORS = { 1: "#038141", 2: "#85BB2F", 3: "#EE8100", 4: "#E63E11" }
export const ECO_COLORS  = { "a-plus": "#006400", a: "#038141", b: "#85BB2F", c: "#FECB02", d: "#EE8100", e: "#E63E11", f: "#8B1A1A" }
export const ECO_LABELS  = { "a-plus": "A+" }

export function escapeHtml(str) {
  const d = document.createElement("div")
  d.textContent = String(str)
  return d.innerHTML
}

// Whitelists a product's raw OFF quality fields against the known grade sets,
// so callers never trust an out-of-range/unrecognized value from the API.
export function parseQualityScores(product) {
  const nsRaw   = product.nutriscore?.toLowerCase()
  const ns      = nsRaw && NS_COLORS[nsRaw] ? nsRaw : null
  const novaRaw = parseInt(product.nova_group)
  const nova    = (!isNaN(novaRaw) && novaRaw >= 1 && novaRaw <= 4) ? novaRaw : null
  const ecoRaw  = product.ecoscore_grade?.toLowerCase()
  const eco     = ecoRaw && ECO_COLORS[ecoRaw] ? ecoRaw : null
  return { ns, nova, eco }
}

export function setBadge(wrapper, badge, value, label, colorsMap) {
  if (!wrapper || !badge) return
  if (value) {
    wrapper.classList.remove("hidden")
    wrapper.classList.add("flex")
    badge.textContent = label || String(value).toUpperCase()
    badge.style.backgroundColor = colorsMap[value] || "#52525B"
  } else {
    wrapper.classList.add("hidden")
    wrapper.classList.remove("flex")
  }
}

export function renderAllergenChips(el, values, map) {
  if (!el) return
  el.innerHTML = ""
  if (values.length) {
    el.className = "flex flex-wrap gap-1.5"
    values.forEach(v => {
      const key   = v.toLowerCase().replace(/-/g, "_")
      const label = map[key] || v.replace(/-/g, " ")
      const span  = document.createElement("span")
      span.className = "inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-status-danger/10 border border-status-danger/30 text-status-danger"
      span.innerHTML = `<i class="fas fa-triangle-exclamation text-[9px]"></i>${escapeHtml(label)}`
      el.appendChild(span)
    })
  } else {
    el.innerHTML = `<span class="text-xs text-ink-subtle">—</span>`
    el.className = ""
  }
}

export function renderTagChips(el, values, map) {
  if (!el) return
  el.innerHTML = ""
  if (values.length) {
    el.className = "flex flex-wrap gap-1.5"
    values.forEach(v => {
      const key = v.toLowerCase().replace(/-/g, "_")
      const label = (map && map[key]) || v.replace(/-/g, " ")
      const span = document.createElement("span")
      span.className = "inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-surface-hover border border-surface-border/50 text-ink-muted"
      span.textContent = label
      el.appendChild(span)
    })
  } else {
    el.textContent = "—"
    el.className = "text-xs text-ink-subtle"
  }
}
