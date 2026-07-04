import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["customForm", "customInput", "customToggle", "customAmountForm", "deltaInput", "resetBtn"]

  toggleCustom() {
    const form = this.customFormTarget
    const open  = form.classList.contains("hidden")
    form.classList.toggle("hidden", !open)
    this.customToggleTarget.classList.toggle("hidden", open)
    if (this.hasResetBtnTarget) this.resetBtnTarget.classList.toggle("hidden", open)
    if (open) this.customInputTarget.focus()
    else this.customInputTarget.value = ""
  }

  submitCustom() {
    const ml = parseInt(this.customInputTarget.value, 10)
    if (!ml || ml <= 0) return

    this.deltaInputTarget.value = ml
    this.customAmountFormTarget.requestSubmit()
    this.customInputTarget.value = ""
  }
}
