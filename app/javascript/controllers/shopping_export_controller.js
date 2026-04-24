import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["copyBtn", "shareBtn"]
  static values  = { title: String, items: Array, categories: Object, copySuccess: String, copyError: String }

  copy() {
    const text = this._buildText()
    if (!text) return

    const btn = this.hasCopyBtnTarget ? this.copyBtnTarget : null
    this._writeToClipboard(
      text,
      () => {
        this._flash(btn, "fa-check", "fa-copy")
        this._toast(this.copySuccessValue, "success")
      },
      () => {
        this._toast(this.copyErrorValue, "error")
      }
    )
  }

  share() {
    const text = this._buildText()
    if (!text) return

    const btn = this.hasShareBtnTarget ? this.shareBtnTarget : null

    if (typeof navigator.share === "function") {
      navigator.share({ text })
        .then(() => this._flash(btn, "fa-check", "fa-share-nodes"))
        .catch(() => {})
    } else {
      this._writeToClipboard(text, () => this._flash(btn, "fa-check", "fa-share-nodes"))
    }
  }

  // ── Private ─────────────────────────────────────────────────────────────

  _buildText() {
    const items = this.itemsValue || []
    if (!this.titleValue) return ""

    const CATS  = this.categoriesValue
    const ORDER = ["proteins", "grains", "vegetables", "fruits", "dairy", "beverages", "condiments", "other"]

    // Group items by category (preserving server-side order)
    const grouped = {}
    items.forEach(item => {
      const cat = item.category || "other"
      if (!grouped[cat]) grouped[cat] = []
      grouped[cat].push(item)
    })

    const activeCats = ORDER.filter(c => grouped[c])
    const lines = [`🛒 ${this.titleValue}`, ""]

    activeCats.forEach((cat, idx) => {
      const { emoji, label } = CATS[cat] || CATS.other
      lines.push(`${emoji} ${label.toUpperCase()}`)
      grouped[cat].forEach(({ name, quantity }) => {
        lines.push(`□ ${name}${quantity ? `  —  ${quantity}` : ""}`)
      })
      if (idx < activeCats.length - 1) lines.push("")
    })

    return lines.join("\n")
  }

  _writeToClipboard(text, onSuccess, onError) {
    if (navigator.clipboard && typeof navigator.clipboard.writeText === "function") {
      navigator.clipboard.writeText(text)
        .then(onSuccess)
        .catch(() => {
          if (this._execCopy(text)) { onSuccess() } else { onError && onError() }
        })
    } else {
      if (this._execCopy(text)) { onSuccess() } else { onError && onError() }
    }
  }

  _execCopy(text) {
    try {
      const ta = document.createElement("textarea")
      ta.value = text
      ta.style.cssText = "position:fixed;top:0;left:0;opacity:0;pointer-events:none"
      document.body.appendChild(ta)
      ta.focus()
      ta.select()
      const ok = document.execCommand("copy")
      document.body.removeChild(ta)
      return ok
    } catch (e) {
      return false
    }
  }

  _toast(message, type) {
    const container = document.getElementById("flash_messages")
    if (!container) return

    const isSuccess = type === "success"
    const colorClass = isSuccess
      ? "bg-status-success/15 border-status-success/40 text-status-success"
      : "bg-status-danger/15 border-status-danger/40 text-status-danger"
    const icon = isSuccess ? "fa-check-circle" : "fa-circle-exclamation"

    const el = document.createElement("div")
    el.className = `pointer-events-auto flex items-center gap-3 px-4 py-3 rounded-xl ${colorClass} border shadow-lg text-sm max-w-sm`
    el.setAttribute("data-controller", "auto-dismiss")
    el.innerHTML = `<i class="fas ${icon} text-base shrink-0"></i><span>${message}</span>`
    container.prepend(el)
  }

  _flash(btn, successIcon, originalIcon) {
    if (!btn || !btn.isConnected) return
    const icon = btn.querySelector("i")
    if (!icon) return
    icon.className = `fas ${successIcon} text-xs`
    btn.disabled = true
    setTimeout(() => {
      if (btn.isConnected) {
        icon.className = `fas ${originalIcon} text-xs`
        btn.disabled = false
      }
    }, 2000)
  }
}
