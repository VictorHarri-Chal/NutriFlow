import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    labels: Array,
    data1:  Array,
    data2:  Array,
    data3:  Array,
    label1: { type: String, default: "" },
    label2: { type: String, default: "" },
    label3: { type: String, default: "" },
    color1: { type: String, default: "#EAB308" },
    color2: { type: String, default: "#34D399" },
    color3: { type: String, default: "#60A5FA" }
  }

  connect() {
    const Chart = window.Chart
    if (!Chart) return

    const gridColor = "rgba(82, 82, 91, 0.25)"
    const tickColor = "#71717A"

    const makeDataset = (data, label, color) => ({
      label,
      data,
      borderColor: color,
      backgroundColor: "transparent",
      fill: false,
      tension: 0.15,
      pointRadius: 2,
      pointHoverRadius: 5,
      pointBackgroundColor: color,
      pointBorderColor: "#18181B",
      pointBorderWidth: 1,
      borderWidth: 1.5,
      spanGaps: false,
    })

    const datasets = []
    if (this.data1Value.length) datasets.push(makeDataset(this.data1Value, this.label1Value, this.color1Value))
    if (this.data2Value.length) datasets.push(makeDataset(this.data2Value, this.label2Value, this.color2Value))
    if (this.data3Value.length) datasets.push(makeDataset(this.data3Value, this.label3Value, this.color3Value))

    this.chart = new Chart(this.element, {
      type: "line",
      data: { labels: this.labelsValue, datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        plugins: {
          legend: {
            display: true,
            position: "bottom",
            labels: {
              color: tickColor,
              boxWidth: 12,
              padding: 16,
              font: { size: 11 }
            }
          },
          tooltip: {
            backgroundColor: "#27272A",
            borderColor: "rgba(82,82,91,0.5)",
            borderWidth: 1,
            titleColor: "#F4F4F5",
            bodyColor: "#A1A1AA",
            padding: 10,
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
            ticks:  { color: tickColor, stepSize: 1, precision: 0 },
            border: { color: gridColor },
            min: 1,
            max: 5,
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
