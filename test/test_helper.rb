ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Routes are drawn lazily in the test env; force them so Devise.mappings is
# populated before `sign_in` runs (otherwise: "Could not find a valid mapping").
Rails.application.reload_routes_unless_loaded

module ActiveSupport
  class TestCase
    fixtures :all

    # ── Inline factory helpers ────────────────────────────────────────────
    # Records are built inline rather than via large fixture sets. Every helper
    # returns a persisted record scoped to its owner, mirroring production.

    def create_user(email: nil, password: "password123", onboarded: true)
      email ||= "user-#{SecureRandom.hex(6)}@example.test"
      user = User.new(email: email, password: password, password_confirmation: password)
      user.skip_confirmation! # sets confirmed_at, skips the confirmation mailer
      user.save!
      # Complete the auto-created profile so the user clears the onboarding gate
      # (ApplicationController#require_onboarding_complete!).
      if onboarded
        user.profile.update!(name: "Test", date_of_birth: Date.new(1990, 1, 1),
                             weight: 75, height: 175, gender: :male)
      end
      user
    end

    def create_food(user:, name: nil, calories: 100, proteins: 10, carbs: 20, fats: 5, sugars: 3, **attrs)
      user.foods.create!(
        name: name || "Food-#{SecureRandom.hex(4)}",
        calories: calories, proteins: proteins, carbs: carbs, fats: fats, sugars: sugars,
        **attrs
      )
    end

    def create_recipe(user:, name: nil, items: [])
      recipe = user.recipes.build(name: name || "Recipe-#{SecureRandom.hex(4)}")
      items.each { |attrs| recipe.recipe_items.build(attrs) }
      recipe.save!
      recipe
    end

    def create_exercise(name: nil, body_part: "chest", equipment: "barbell", custom_user: nil)
      Exercise.create!(
        exercise_id: "test-#{SecureRandom.hex(6)}",
        name: name || "Exercise-#{SecureRandom.hex(4)}",
        body_part: body_part, equipment: equipment, custom_user: custom_user
      )
    end

    def create_weight_entry(user:, date: Date.today, weight_kg: 75.0)
      user.weight_entries.create!(date: date, weight_kg: weight_kg)
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
