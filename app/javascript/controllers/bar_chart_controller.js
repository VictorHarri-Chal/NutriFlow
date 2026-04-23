import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    labels: Array,
    data:   Array,
    label:  { type: String, default: "" },
    unit:   { type: String, default: "" },
    color:  { type: String, default: "#EAB308" }
  }

  connect() {
    const Chart = window.Chart
    if (!Chart) return

    const color     = this.colorValue
    const gridColor = "rgba(82, 82, 91, 0.25)"
    const tickColor = "#71717A"
    const unit      = this.unitValue

    this.chart = new Chart(this.element, {
      type: "bar",
      data: {
        labels: this.labelsValue,
        datasets: [{
          label: this.labelValue,
          data: this.dataValue,
          backgroundColor: `${color}33`,
          borderColor: color,
          borderWidth: 1.5,
          borderRadius: 4,
          borderSkipped: false,
          maxBarThickness: 56,
        }]
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
              label: ctx => ` ${ctx.parsed.y}${unit ? " " + unit : ""}`
            }
          }
        },
        scales: {
          x: {
            grid:   { color: "transparent" },
            ticks:  { color: tickColor, maxRotation: 0 },
            border: { color: gridColor }
          },
          y: {
            grid:   { color: gridColor },
            ticks:  {
              color: tickColor,
              precision: 0
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
