class Day < ApplicationRecord
  belongs_to :user
  has_many :day_foods, dependent: :destroy
  has_many :foods, through: :day_foods
  has_many :day_recipes, dependent: :destroy
  has_many :recipes, through: :day_recipes
  has_many :workout_sessions, dependent: :destroy
  has_many :cardio_sessions,  dependent: :destroy, inverse_of: :day

  validates :date, presence: true, uniqueness: { scope: :user_id }
  validates :note, length: { maximum: 1000 }, allow_blank: true

  scope :for_date, ->(date) { where(date: date) }

  # Steps for this day — falls back to profile default, then 6 000
  def effective_steps(profile = nil)
    return steps if steps.present?

    profile ||= user&.profile
    profile&.default_daily_steps || 6_000
  end

  # Sum of calories burned across all workout sessions + cardio for this day
  def workout_calories_total
    strength_kcal = if workout_sessions.loaded?
      workout_sessions.sum { |s| s.calories_burned.to_i }
    else
      workout_sessions.sum(:calories_burned).to_i
    end

    cardio_kcal = CardioBlock.joins(:cardio_session)
                             .where(cardio_sessions: { day_id: id })
                             .sum(:calories_burned).to_i

    strength_kcal + cardio_kcal
  end

  def total_calories
    preloaded_day_foods.sum(&:total_calories) + preloaded_day_recipes.sum(&:total_calories)
  end

  def total_proteins
    preloaded_day_foods.sum(&:total_proteins) + preloaded_day_recipes.sum(&:total_proteins)
  end

  def total_carbs
    preloaded_day_foods.sum(&:total_carbs) + preloaded_day_recipes.sum(&:total_carbs)
  end

  def total_fats
    preloaded_day_foods.sum(&:total_fats) + preloaded_day_recipes.sum(&:total_fats)
  end

  def total_sugars
    preloaded_day_foods.sum(&:total_sugars) + preloaded_day_recipes.sum(&:total_sugars)
  end

  private

  def preloaded_day_foods
    day_foods.loaded? ? day_foods : day_foods.includes(:food)
  end

  def preloaded_day_recipes
    day_recipes.loaded? ? day_recipes : day_recipes.includes(recipe: { recipe_items: :food })
  end
end
