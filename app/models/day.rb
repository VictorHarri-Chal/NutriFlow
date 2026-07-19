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

    cardio_kcal = if cardio_sessions.loaded? && cardio_sessions.all? { |cs| cs.cardio_blocks.loaded? }
      cardio_sessions.sum { |cs| cs.cardio_blocks.sum { |cb| cb.calories_burned.to_i } }
    else
      CardioBlock.joins(:cardio_session)
                 .where(cardio_sessions: { day_id: id })
                 .sum(:calories_burned).to_i
    end

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

  def aggregated_micronutrients
    @aggregated_micronutrients ||= (preloaded_day_foods + preloaded_day_recipes)
      .each_with_object({}) do |item, acc|
        item.scaled_micronutrients.each { |key, value| acc[key] = (acc[key] || 0) + value }
      end.transform_values { |v| v.round(2) }.reject { |_, v| v.zero? }
  end

  # Accepte un `user:` déjà chargé (ex: CalendarDataLoader a déjà `current_user`
  # en mémoire) pour éviter un aller-retour SQL évitable sur `user` — sinon
  # `self.user` (l'association `belongs_to`) déclenche sa propre requête,
  # distincte de toute instance de User déjà en mémoire côté appelant.
  def week_aggregated_micronutrients(user: self.user)
    week_range = date.beginning_of_week..date.end_of_week
    user.days.where(date: week_range)
        .includes(day_foods: :food, day_recipes: { recipe: { recipe_items: :food }, day_recipe_items: :food })
        .each_with_object({}) do |d, acc|
          d.aggregated_micronutrients.each { |key, value| acc[key] = (acc[key] || 0) + value }
        end.transform_values { |v| v.round(2) }
  end

  # Toujours les 14 clés de Micronutrient::ALL, même à 0 — jamais seulement
  # celles consommées (le panneau calendrier doit montrer les manques).
  def micronutrient_coverage(user: self.user, profile: user&.profile)
    consumed = week_aggregated_micronutrients(user: user)
    goals    = profile&.weekly_micronutrient_goals || {}

    Micronutrient::ALL.each_with_object({}) do |entry, acc|
      value = consumed[entry.key.to_s].to_f
      goal  = goals[entry.key]
      acc[entry.key] = {
        consumed:   value,
        goal:       goal,
        percentage: Micronutrient.coverage_percentage(value, goal),
        nature:     entry.nature
      }
    end
  end

  private

  def preloaded_day_foods
    @preloaded_day_foods ||= day_foods.loaded? ? day_foods.to_a : day_foods.includes(:food).to_a
  end

  def preloaded_day_recipes
    @preloaded_day_recipes ||= day_recipes.loaded? ? day_recipes.to_a : day_recipes.includes(recipe: { recipe_items: :food }).to_a
  end
end
