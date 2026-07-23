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

    // None of the numeric fields this controller is used on (quantities, weights,
    // reps, macros…) accept a negative value or letters — strip anything that
    // isn't a digit, comma, or period outright instead of waiting for submit-time
    // validation. This also covers type="text" fields (e.g. the ingredient
    // quantity input), which — unlike type="number" — have no native keystroke
    // filtering of their own.
    // A French-locale user typing "," for the decimal separator would otherwise see
    // the browser silently reject the keystroke on a type="number" input — normalize
    // it to "." so the value is actually accepted.
    const raw = value.replace(/[^\d,.]/g, "").replace(",", ".")
    const [integerPart, decimalPart] = raw.split(".")

    let truncatedInteger = integerPart
    let truncatedDecimal = decimalPart
    if (integerPart.length > this.maxIntegerDigitsValue) {
      truncatedInteger = integerPart.slice(0, this.maxIntegerDigitsValue)
    }
    if (decimalPart !== undefined && decimalPart.length > this.maxDecimalDigitsValue) {
      truncatedDecimal = decimalPart.slice(0, this.maxDecimalDigitsValue)
    }

    // Only keep the decimal point if a decimal digit actually survives
    // truncation (e.g. maxDecimalDigits: 0) — writing back "1234." would be
    // an invalid number for a number input, which the browser silently
    // resets to "", leaving the field stuck unable to accept further input.
    let truncated = truncatedInteger
    if (decimalPart !== undefined && truncatedDecimal.length > 0) truncated += `.${truncatedDecimal}`

    if (truncated !== value) input.value = truncated
  }
}
