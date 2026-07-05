// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "tooltip"

// Auto-scroll to the inline form when it loads with content
document.addEventListener("turbo:frame-load", (event) => {
  if (["workout_item_form", "cardio_item_form", "food_item_form"].includes(event.target.id) && event.target.innerHTML.trim() !== "") {
    setTimeout(() => {
      event.target.scrollIntoView({ behavior: "smooth", block: "nearest" })
    }, 50)
  }
})
