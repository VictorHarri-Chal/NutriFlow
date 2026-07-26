import { Controller } from "@hotwired/stimulus"
import { PALETTE } from "chart_palette"

const DEFAULT_PALETTE = [
  PALETTE.brand, PALETTE.macro.proteins, PALETTE.macro.calories,
  PALETTE.macro.fats, PALETTE.macro.sugars, PALETTE.macro.carbs
]

export default class extends Controller {
  static values = {
    labels: Array,
    data:   Array,
    colors: { type: Array, default: [] }
  }

  connect() {
    const Chart = window.Chart
    if (!Chart) return

    const palette = this.colorsValue.length > 0 ? this.colorsValue : DEFAULT_PALETTE

    this.chart = new Chart(this.element, {
      type: "doughnut",
      data: {
        labels: this.labelsValue,
        datasets: [{
          data: this.dataValue,
          backgroundColor: palette.map(c => `${c}99`),
          borderColor: palette,
          borderWidth: 1.5,
          hoverOffset: 4,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: "68%",
        plugins: {
          legend: {
            position: "right",
            labels: {
              color: PALETTE.ink.muted,
              font: { size: 12 },
              padding: 14,
              boxWidth: 10,
              usePointStyle: true,
              pointStyle: "circle"
            }
          },
          tooltip: {
            backgroundColor: PALETTE.surface.raised,
            borderColor: "rgba(82,82,91,0.5)",
            borderWidth: 1,
            titleColor: PALETTE.ink.primary,
            bodyColor: PALETTE.ink.muted,
            padding: 10,
            callbacks: {
              label: ctx => {
                const total = ctx.dataset.data.reduce((a, b) => a + b, 0)
                const pct   = total > 0 ? Math.round(ctx.parsed / total * 100) : 0
                return ` ${ctx.label}: ${ctx.parsed} (${pct}%)`
              }
            }
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
