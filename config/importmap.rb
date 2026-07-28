# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "sortablejs" # vendored in vendor/javascript/sortablejs.js (was jsdelivr CDN)
pin "tooltip", to: "tooltip.js"
pin "unit_conversions", to: "unit_conversions.js"
pin "chart_formatters", to: "chart_formatters.js"
pin "chart_palette", to: "chart_palette.js"
pin "off_product_renderer", to: "off_product_renderer.js"
pin_all_from "app/javascript/controllers", under: "controllers"
