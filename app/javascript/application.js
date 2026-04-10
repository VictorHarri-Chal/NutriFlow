// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Auto-scroll to the inline form when it loads with content
document.addEventListener("turbo:frame-load", (event) => {
  if (event.target.id === "item_form" && event.target.innerHTML.trim() !== "") {
    setTimeout(() => {
      event.target.scrollIntoView({ behavior: "smooth", block: "nearest" })
    }, 50)
  }
})
