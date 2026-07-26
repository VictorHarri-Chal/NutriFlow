import { Controller } from "@hotwired/stimulus"
import { formatChartNumber } from "chart_formatters"
import { PALETTE } from "chart_palette"

export default class extends Controller {
  static values = {
    labels: Array,
    data:   Array,
    label:  { type: String, default: "" },
    unit:   { type: String, default: "" },
    goal:   { type: Number, default: 0 },
    color:  { type: String, default: PALETTE.brand }
  }

  connect() {
    const Chart = window.Chart
    if (!Chart) return

    const color     = this.colorValue
    const gridColor = "rgba(82, 82, 91, 0.25)"
    const tickColor = PALETTE.ink.subtle
    const unit      = this.unitValue

    this.chart = new Chart(this.element, {
      type: "line",
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            label: this.labelValue,
            data: this.dataValue,
            borderColor: color,
            backgroundColor: `${color}14`,
            fill: true,
            tension: 0.4,
            pointRadius: 3,
            pointHoverRadius: 6,
            pointBackgroundColor: color,
            pointBorderColor: PALETTE.surface.base,
            pointBorderWidth: 1.5,
            borderWidth: 2,
          },
          ...(this.goalValue > 0 ? [{
            label: "Objectif",
            data: this.labelsValue.map(() => this.goalValue),
            borderColor: "rgba(34, 197, 94, 0.5)",
            borderDash: [6, 4],
            borderWidth: 1.5,
            pointRadius: 0,
            fill: false,
            tension: 0,
          }] : [])
        ]
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
              label: ctx => ` ${formatChartNumber(ctx.parsed.y)}${unit ? " " + unit : ""}`
            }
          }
        },
        scales: {
          x: {
            grid:   { color: gridColor },
            ticks:  { color: tickColor, maxTicksLimit: 8, maxRotation: 0 },
            border: { color: gridColor }
          },
          y: {
            grid:   { color: gridColor },
            ticks:  {
              color: tickColor,
              callback: val => `${formatChartNumber(val)}${unit ? " " + unit : ""}`
            },
            border:      { color: gridColor },
            beginAtZero: true
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
