/**
 * Global custom tooltip system.
 * – Strips native `title` attributes (preventing browser default tooltip)
 * – Shows a custom-styled tooltip with a 200ms delay
 * – Auto-positions above/below, clamped to the viewport
 * – Stable across Turbo navigations and tab switches
 */

let tipEl       = null
let showTimer   = null
let hideTimer   = null

// ─── Element ──────────────────────────────────────────────────────────────────

function getEl() {
  if (!tipEl) {
    tipEl = document.createElement('div')
    tipEl.id = 'custom-tooltip'
    tipEl.setAttribute('role', 'tooltip')
    tipEl.setAttribute('aria-hidden', 'true')
    document.body.appendChild(tipEl)
  }
  return tipEl
}

// ─── Show / hide ──────────────────────────────────────────────────────────────

function show(e) {
  const target = e.currentTarget
  const text   = target.dataset.tooltip
  if (!text?.trim()) return

  clearTimeout(showTimer)
  clearTimeout(hideTimer)

  showTimer = setTimeout(() => {
    // Guard: element must still be in the DOM
    if (!document.contains(target)) return

    const tip = getEl()
    tip.textContent   = text
    tip.style.display = 'block'
    tip.style.opacity = '0'
    tip.style.transform = 'translateY(4px)'

    // Two-frame render so the browser has sized the tooltip before positioning
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        if (!document.contains(target)) { hide(); return }
        position(target, tip)
        tip.style.opacity   = '1'
        tip.style.transform = 'translateY(0)'
      })
    })
  }, 200)
}

function hide() {
  clearTimeout(showTimer)
  clearTimeout(hideTimer)

  if (!tipEl) return
  tipEl.style.opacity   = '0'
  tipEl.style.transform = 'translateY(4px)'

  // Set display:none after transition completes so it doesn't affect layout
  hideTimer = setTimeout(() => {
    if (tipEl) tipEl.style.display = 'none'
  }, 130)
}

// ─── Positioning ──────────────────────────────────────────────────────────────

function position(target, tip) {
  const r   = target.getBoundingClientRect()
  const t   = tip.getBoundingClientRect()
  const gap = 8

  let top  = r.bottom + gap
  let left = r.left + r.width / 2 - t.width / 2

  // Flip above if not enough room below
  if (top + t.height > window.innerHeight - 8) {
    top = r.top - t.height - gap
  }

  // Clamp horizontally within viewport
  left = Math.max(8, Math.min(left, window.innerWidth - t.width - 8))

  tip.style.top  = top  + 'px'
  tip.style.left = left + 'px'
}

// ─── Binding ──────────────────────────────────────────────────────────────────

function bind(node) {
  if (node.dataset.tooltipBound) return
  node.dataset.tooltipBound = 'true'
  node.addEventListener('mouseenter', show)
  node.addEventListener('mouseleave', hide)
  node.addEventListener('click',      hide)
  node.addEventListener('focus',      show)
  node.addEventListener('blur',       hide)
}

function init(root = document) {
  if (!root?.querySelectorAll) return

  // Convert title → data-tooltip, suppressing the native browser tooltip
  root.querySelectorAll('[title]').forEach(node => {
    if (node.closest?.('head') || node.dataset.tooltipSkip != null) return
    const val = node.getAttribute('title')
    if (val?.trim()) {
      node.dataset.tooltip = val
      node.removeAttribute('title')
    }
  })

  // Attach listeners to unbound tooltip elements
  root.querySelectorAll('[data-tooltip]:not([data-tooltip-bound])').forEach(bind)

  // Handle the root itself if it carries the attribute
  if (root.dataset?.tooltip && !root.dataset.tooltipBound) bind(root)
}

// ─── MutationObserver ─────────────────────────────────────────────────────────

const observer = new MutationObserver(mutations => {
  for (const m of mutations) {
    for (const node of m.addedNodes) {
      if (node.nodeType !== 1) continue
      init(node)
    }
  }
})

function observeBody() {
  observer.disconnect()
  observer.observe(document.body, { childList: true, subtree: true })
  // Re-append tooltip element to the current body (may have been swapped by Turbo)
  if (tipEl && !document.body.contains(tipEl)) {
    document.body.appendChild(tipEl)
  }
}

// ─── Lifecycle hooks ──────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', () => {
  init()
  observeBody()
})

// Re-init + re-observe after every Turbo Drive navigation (body is swapped)
document.addEventListener('turbo:load', () => {
  hide()
  init()
  observeBody()
})

// Partial frame loads
document.addEventListener('turbo:frame-load', e => init(e.target))

// When returning to a previously cached page, re-bind (no full init needed)
document.addEventListener('turbo:render', () => init())

// Hide tooltip when leaving the page so it doesn't persist on back-navigation
document.addEventListener('turbo:before-visit', () => hide())

// Hide and reset when tab becomes visible again (stale hover state)
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') hide()
})
