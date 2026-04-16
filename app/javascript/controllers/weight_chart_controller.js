import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    labels: Array,
    data:   Array,
    goal:   Number
  }

  connect() {
    const Chart = window.Chart
    if (!Chart) return

    const amber     = "#EAB308"
    const gridColor = "rgba(82, 82, 91, 0.25)"
    const tickColor = "#71717A"

    this.chart = new Chart(this.element, {
      type: "line",
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            label: "Poids (kg)",
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
            backgroundColor: "#27272A",
            borderColor: "rgba(82,82,91,0.5)",
            borderWidth: 1,
            titleColor: "#F4F4F5",
            bodyColor: "#A1A1AA",
            padding: 10,
            callbacks: {
              label: ctx => ` ${ctx.parsed.y} kg`
            }
          }
        },
        scales: {
          x: {
            grid:  { color: gridColor },
            ticks: { color: tickColor, maxTicksLimit: 7, maxRotation: 0 },
            border: { color: gridColor }
          },
          y: {
            grid:  { color: gridColor },
            ticks: {
              color: tickColor,
              callback: val => `${val} kg`
            },
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
