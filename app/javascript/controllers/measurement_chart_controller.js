import { Controller } from "@hotwired/stimulus"
import { formatChartNumber } from "chart_formatters"
import { PALETTE } from "chart_palette"

export default class extends Controller {
  static values = {
    labels: Array,
    data:   Array
  }

  connect() {
    const Chart = window.Chart
    if (!Chart) return

    const amber     = PALETTE.brand
    const gridColor = "rgba(82, 82, 91, 0.25)"
    const tickColor = PALETTE.ink.subtle

    this.chart = new Chart(this.element, {
      type: "line",
      data: {
        labels: this.labelsValue,
        datasets: [{
          label: "Mesure (cm)",
          data: this.dataValue,
          borderColor: amber,
          backgroundColor: "rgba(234, 179, 8, 0.08)",
          fill: true,
          tension: 0.4,
          pointRadius: 3,
          pointHoverRadius: 6,
          pointBackgroundColor: amber,
          pointBorderColor: "#18181B",
          pointBorderWidth: 1.5,
          borderWidth: 2,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: PALETTE.surface.raised,
            borderColor: "rgba(82,82,91,0.5)",
            borderWidth: 1,
            titleColor: PALETTE.ink.primary,
            bodyColor: PALETTE.ink.muted,
            padding: 10,
            callbacks: {
              label: ctx => ctx.parsed.y !== null ? ` ${formatChartNumber(ctx.parsed.y)} cm` : null
            }
          }
        },
        scales: {
          x: {
            grid:  { color: gridColor },
            ticks: { color: tickColor, maxTicksLimit: 8, maxRotation: 0 },
            border: { color: gridColor }
          },
          y: {
            grid:  { color: gridColor },
            ticks: { color: tickColor, callback: val => `${formatChartNumber(val)} cm` },
            border:      { color: gridColor },
            beginAtZero: false
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
