// Shared grams-per-unit table for food quantities (g/kg/mL/L) — used by every
// controller that scales a food's per-100g macros by a quantity+unit pair
// (recipe_builder_controller, day_recipe_preview_controller). Mirrors the
// server-side UNIT_GRAM_MULTIPLIERS in app/models/concerns/has_food_quantity.rb.
export const UNIT_GRAM_MULTIPLIERS = {
  g: 1.0,
  kg: 1000.0,
  mL: 1.0,
  L: 1000.0
}
