import { Controller } from "@hotwired/stimulus"

// Truncates typed digits on number inputs as the user types, since native
// `maxlength` is not enforced by browsers on <input type="number">.
export default class extends Controller {
  static values = {
    maxIntegerDigits: Number,
    maxDecimalDigits: { type: Number, default: 0 }
  }

  limit(event) {
    const input = event.target
    const value = input.value
    if (value === "") return

    const negative = value.startsWith("-")
    const raw = negative ? value.slice(1) : value
    const [integerPart, decimalPart] = raw.split(".")

    let truncatedInteger = integerPart
    let changed = false

    if (integerPart.length > this.maxIntegerDigitsValue) {
      truncatedInteger = integerPart.slice(0, this.maxIntegerDigitsValue)
      changed = true
    }

    let truncatedDecimal = decimalPart
    if (decimalPart !== undefined && decimalPart.length > this.maxDecimalDigitsValue) {
      truncatedDecimal = decimalPart.slice(0, this.maxDecimalDigitsValue)
      changed = true
    }

    if (!changed) return

    // Only keep the decimal point if a decimal digit actually survives
    // truncation (e.g. maxDecimalDigits: 0) — writing back "1234." would be
    // an invalid number for a number input, which the browser silently
    // resets to "", leaving the field stuck unable to accept further input.
    let truncated = truncatedInteger
    if (decimalPart !== undefined && truncatedDecimal.length > 0) truncated += `.${truncatedDecimal}`
    input.value = negative ? `-${truncated}` : truncated
  }
}
