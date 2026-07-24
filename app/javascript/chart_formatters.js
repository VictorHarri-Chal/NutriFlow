// Shared Chart.js formatting helpers.
//
// Chart.js generates y-axis ticks by dividing the value range, which yields
// floating-point artifacts (e.g. 59.00000000000001). Round to at most two
// decimals and drop trailing zeros so ticks and tooltips read cleanly.
export function formatChartNumber(value) {
  return Number(Number(value).toFixed(2)).toString()
}
