import { Controller } from "@hotwired/stimulus"
import { formatChartNumber } from "chart_formatters"

export default class extends Controller {
  static values = {
    labels:     Array,
    data:       Array,
    goal:       Number,
    projLabels: Array,
    projData:   Array
  }

  connect() {
    const Chart = window.Chart
    if (!Chart) return

    const amber     = "#EAB308"
    const gridColor = "rgba(82, 82, 91, 0.25)"
    const tickColor = "#71717A"

    const hasProj  = this.projLabelsValue.length > 0
    const allLabels = hasProj
      ? [...this.labelsValue, ...this.projLabelsValue]
      : this.labelsValue

    const weightData = hasProj
      ? [...this.dataValue, ...Array(this.projLabelsValue.length).fill(null)]
      : this.dataValue

    const projDataset = hasProj ? {
      label: "Projection",
      data: [...Array(this.dataValue.length - 1).fill(null), this.dataValue.at(-1), ...this.projDataValue],
      borderColor: "rgba(234, 179, 8, 0.35)",
      borderDash: [5, 4],
      borderWidth: 1.5,
      pointRadius: 0,
      fill: false,
      tension: 0.3,
      spanGaps: true,
    } : null

    this.chart = new Chart(this.element, {
      type: "line",
      data: {
        labels: allLabels,
        datasets: [
          {
            label: "Poids (kg)",
            data: weightData,
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
            spanGaps: false,
          },
          ...(projDataset ? [projDataset] : []),
          ...(this.goalValue > 0 ? [{
            label: "Objectif",
            data: allLabels.map(() => this.goalValue),
            borderColor: "rgba(52, 211, 153, 0.5)",
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
            backgroundColor: "#27272A",
            borderColor: "rgba(82,82,91,0.5)",
            borderWidth: 1,
            titleColor: "#F4F4F5",
            bodyColor: "#A1A1AA",
            padding: 10,
            callbacks: {
              label: ctx => ctx.parsed.y !== null ? ` ${formatChartNumber(ctx.parsed.y)} kg` : null
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
            ticks: { color: tickColor, callback: val => `${formatChartNumber(val)} kg` },
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
