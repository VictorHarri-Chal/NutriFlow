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

  # Denormalized daily totals, kept in sync by #recompute_totals! on any
  # day_food/day_recipe change. Logs are snapshot-based (HasFoodSnapshot), so a
  # later edit/deletion of the source Food/Recipe never changes these — no
  # cascade from Food/Recipe is needed. Float for display parity with the sum.
  def total_calories = self[:cached_calories].to_f
  def total_proteins = self[:cached_proteins].to_f
  def total_carbs    = self[:cached_carbs].to_f
  def total_fats     = self[:cached_fats].to_f
  def total_sugars   = self[:cached_sugars].to_f

  # Recompute + persist the cached totals. update_columns fires no callbacks (no
  # recursion) and bumps updated_at so the statistics conditional-GET ETag stays
  # reliable (any change to the day's logged foods/recipes moves its timestamp).
  def recompute_totals!
    t = compute_live_totals
    update_columns(
      cached_calories: t[:calories], cached_proteins: t[:proteins], cached_carbs: t[:carbs],
      cached_fats: t[:fats], cached_sugars: t[:sugars], updated_at: Time.current
    )
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
        .includes(:day_foods, day_recipes: :day_recipe_items)
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

  # Live aggregation the cached_* columns mirror. day_food/day_recipe totals are
  # read from their frozen snapshots (day_recipe totals sum their own items).
  # Queried fresh by day_id (not via the association) so it reflects the committed
  # rows even when triggered mid-create — collection#create! fires after_save
  # BEFORE appending the new record to a loaded association target.
  def compute_live_totals
    entries = DayFood.where(day_id: id).to_a +
              DayRecipe.where(day_id: id).includes(:day_recipe_items).to_a
    {
      calories: entries.sum { |e| e.total_calories.to_f }.round(2),
      proteins: entries.sum { |e| e.total_proteins.to_f }.round(2),
      carbs:    entries.sum { |e| e.total_carbs.to_f }.round(2),
      fats:     entries.sum { |e| e.total_fats.to_f }.round(2),
      sugars:   entries.sum { |e| e.total_sugars.to_f }.round(2)
    }
  end

  def preloaded_day_foods
    @preloaded_day_foods ||= day_foods.to_a
  end

  def preloaded_day_recipes
    @preloaded_day_recipes ||= day_recipes.loaded? ? day_recipes.to_a : day_recipes.includes(:day_recipe_items).to_a
  end
end
