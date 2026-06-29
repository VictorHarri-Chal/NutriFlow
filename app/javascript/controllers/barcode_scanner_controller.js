import { Controller } from "@hotwired/stimulus"

const QUAGGA_CDN = "https://cdn.jsdelivr.net/npm/@ericblade/quagga2/dist/quagga.min.js"
const EAN_FORMATS = ["ean_13", "ean_8", "upc_a", "upc_e"]

export default class extends Controller {
  static targets = [
    "defaultContent", "cameraPanel", "video",
    "manualInput", "submitBtn", "status", "error", "cancelBtn",
    "urlInput", "urlSubmitBtn"
  ]

  static VALID_LENGTHS = [8, 12, 13]
  static values = { url: String }

  connect() {
    this._stream    = null
    this._detector  = null
    this._animFrame = null
    this._scanning  = false
    this._lastCode  = null
  }

  disconnect() {
    this._stopCamera()
  }

  async openCamera() {
    this._clearError()
    this._clearStatus()
    this._lastCode = null
    this.defaultContentTarget.classList.add("hidden")
    this.cameraPanelTarget.classList.remove("hidden")
    if (this.hasCancelBtnTarget) this.cancelBtnTarget.classList.add("hidden")
    await this._startCamera()
  }

  closeCamera() {
    this._stopCamera()
    this.cameraPanelTarget.classList.add("hidden")
    this.defaultContentTarget.classList.remove("hidden")
    if (this.hasCancelBtnTarget) this.cancelBtnTarget.classList.remove("hidden")
    this._clearError()
    this._clearStatus()
    this._lastCode = null
  }

  validateManualInput() {
    const code = this.manualInputTarget.value.trim().replace(/\D/g, "")
    const valid = this.constructor.VALID_LENGTHS.includes(code.length)
    this.submitBtnTarget.disabled = !valid
  }

  submitManual() {
    this._clearError()
    const code = this.manualInputTarget.value.trim().replace(/\D/g, "")
    if (!this.constructor.VALID_LENGTHS.includes(code.length)) return

    if (!this.cameraPanelTarget.classList.contains("hidden")) {
      this._stopCamera()
      this.cameraPanelTarget.classList.add("hidden")
      this.defaultContentTarget.classList.remove("hidden")
    }
    this._lookupBarcode(code)
  }

  async _startCamera() {
    try {
      if ("BarcodeDetector" in window) {
        const supported = await BarcodeDetector.getSupportedFormats()
        const formats = EAN_FORMATS.filter(f => supported.includes(f))

        if (formats.length > 0) {
          this._stream = await navigator.mediaDevices.getUserMedia({
            video: { facingMode: { ideal: "environment" } }
          })
          this.videoTarget.srcObject = this._stream
          await this.videoTarget.play()
          this._detector = new BarcodeDetector({ formats })
          this._scanning = true
          this._scanNative()
          return
        }
      }

      await this._loadQuagga()
      this._scanQuagga()
    } catch (e) {
      const msg = e.name === "NotAllowedError"
        ? this.element.dataset.barcodeScannerCameraDeniedText || ""
        : this.element.dataset.barcodeScannerCameraErrorText  || ""
      this._showError(msg)
      this.cameraPanelTarget.classList.add("hidden")
      this.defaultContentTarget.classList.remove("hidden")
      if (this.hasCancelBtnTarget) this.cancelBtnTarget.classList.remove("hidden")
    }
  }

  _stopCamera() {
    this._scanning = false
    cancelAnimationFrame(this._animFrame)
    if (this._stream) {
      this._stream.getTracks().forEach(t => t.stop())
      this._stream = null
    }
    if (typeof Quagga !== "undefined") {
      try { Quagga.stop() } catch {}
    }
  }

  _scanNative() {
    const scan = async () => {
      if (!this._scanning) return
      try {
        const codes = await this._detector.detect(this.videoTarget)
        if (codes.length && codes[0].rawValue !== this._lastCode) {
          const code = codes[0].rawValue
          this._lastCode = code
          this._scanning = false
          await this._lookupBarcode(code)
          if (!this.cameraPanelTarget.classList.contains("hidden")) {
            this._scanning = true
            this._animFrame = requestAnimationFrame(scan)
          }
          return
        }
      } catch {}
      if (this._scanning) this._animFrame = requestAnimationFrame(scan)
    }
    this._animFrame = requestAnimationFrame(scan)
  }

  _scanQuagga() {
    Quagga.init({
      inputStream: {
        name: "Live",
        type: "LiveStream",
        target: this.videoTarget.parentElement,
        constraints: { facingMode: "environment" }
      },
      decoder: { readers: ["ean_reader", "ean_8_reader", "upc_reader"] },
      numOfWorkers: 0
    }, (err) => {
      if (err) {
        this._showError(this.element.dataset.barcodeScannerCameraErrorText || "")
        this.cameraPanelTarget.classList.add("hidden")
        this.defaultContentTarget.classList.remove("hidden")
        if (this.hasCancelBtnTarget) this.cancelBtnTarget.classList.remove("hidden")
        return
      }
      Quagga.start()
    })

    Quagga.onDetected(async (result) => {
      const code = result.codeResult.code
      if (code === this._lastCode) return
      this._lastCode = code
      await this._lookupBarcode(code)
    })
  }

  _loadQuagga() {
    if (typeof Quagga !== "undefined") return Promise.resolve()
    return new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = QUAGGA_CDN
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }

  validateUrlInput() {
    const input = this.urlInputTarget.value.trim()
    this.urlSubmitBtnTarget.disabled = !this._isValidOffUrl(input)
  }

  submitUrl() {
    this._clearError()
    const input = this.urlInputTarget.value.trim()
    if (!this._isValidOffUrl(input)) {
      this._showError(this.element.dataset.barcodeScannerUrlInvalidText || "")
      return
    }
    this._lookupBarcode(this._extractBarcode(input))
  }

  _isValidOffUrl(input) {
    return input.includes("openfoodfacts.org") && !!this._extractBarcode(input)
  }

  _extractBarcode(input) {
    const match = input.match(/(?<!\d)(\d{8,13})(?!\d)/)
    return match ? match[1] : null
  }

  async _lookupBarcode(code) {
    this._clearError()
    this._setStatus(this.element.dataset.barcodeScannerSearchingText || "")
    try {
      const res  = await fetch(`${this.urlValue}?code=${encodeURIComponent(code)}`)
      const data = await res.json()
      this._clearStatus()

      if (!res.ok) {
        this._showError(data.error || this.element.dataset.barcodeScannerNotFoundText || "")
        this._lastCode = null
        return
      }

      if (data.existing_food) {
        const foodId = data.existing_food.id
        document.addEventListener("turbo:load", () => {
          const frame = document.getElementById("food_show_panel")
          if (frame) frame.src = `/foods/${foodId}`
        }, { once: true })
        Turbo.visit("/foods")
        return
      }

      this.manualInputTarget.value = ""
      this.submitBtnTarget.disabled = true
      if (this.hasUrlInputTarget)       this.urlInputTarget.value = ""
      if (this.hasUrlSubmitBtnTarget)   this.urlSubmitBtnTarget.disabled = true
      document.dispatchEvent(new CustomEvent("barcode-scanner:product", {
        detail: { product: data.product },
        bubbles: true
      }))
      this.closeCamera()
    } catch {
      this._clearStatus()
      this._showError(this.element.dataset.barcodeScannerNetworkErrorText || "")
      this._lastCode = null
    }
  }

  _setStatus(msg) {
    this.statusTarget.textContent = msg
    this.statusTarget.classList.remove("hidden")
  }

  _clearStatus() {
    this.statusTarget.classList.add("hidden")
    this.statusTarget.textContent = ""
  }

  _showError(msg) {
    this.errorTarget.textContent = msg
    this.errorTarget.classList.remove("hidden")
  }

  _clearError() {
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }
}
