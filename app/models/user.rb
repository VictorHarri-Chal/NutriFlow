class User < ApplicationRecord
  AVAILABLE_LOCALES = %w[fr en].freeze

  AVAILABLE_TIME_ZONES = %w[
    Europe/Paris Europe/London Europe/Brussels Europe/Zurich Europe/Madrid
    Europe/Berlin Europe/Lisbon
    America/New_York America/Chicago America/Denver America/Los_Angeles
    America/Toronto America/Montreal
    Atlantic/Canary Indian/Reunion
  ].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  validates :locale, inclusion: { in: AVAILABLE_LOCALES }
  validates :time_zone, inclusion: { in: AVAILABLE_TIME_ZONES }

  # Declaration order matters for account/data destruction: Food guards
  # itself with dependent: :restrict_with_error against day_foods/recipe_items,
  # workout_sets/program_exercises hold non-cascading FKs to exercises, and
  # WeightEntry#after_destroy syncs its weight onto the (cached) profile — so
  # days/recipes/food_labels must be destroyed before foods, days/workout_programs
  # before exercises, and profile must be destroyed last of all.
  has_many :days,           dependent: :destroy
  has_many :recipes,        dependent: :destroy
  has_many :shopping_lists, dependent: :destroy
  has_many :food_labels,    dependent: :destroy
  has_many :foods,          dependent: :destroy
  has_many :day_food_groups,      dependent: :destroy
  has_many :weight_entries,       dependent: :destroy
  has_many :body_measurements,    dependent: :destroy
  has_many :exercise_favorites,   dependent: :destroy
  has_many :favorited_exercises,  through: :exercise_favorites, source: :exercise
  has_many :workout_programs,     dependent: :destroy
  has_many :exercises,            foreign_key: :custom_user_id, dependent: :destroy
  has_one  :profile,              dependent: :destroy

  after_create :create_profile
  before_create { self.session_token ||= generate_session_token }

  def active_shopping_list
    shopping_lists.active.order(created_at: :asc).first_or_create!(
      name: I18n.t("views.shopping_lists.default_name")
    )
  end

  # Overridden to fold session_token into Devise's session/remember-me salt —
  # regenerating it invalidates every other session and "remember me" cookie
  # without needing a separate session store or before_action check.
  def authenticatable_salt
    "#{super}#{session_token}"
  end

  def invalidate_other_sessions!
    update!(session_token: generate_session_token)
  end

  # Wipes every owned record but keeps the account itself (login, email,
  # preferences). Same destruction order as the has_many declarations above,
  # for the same reasons. Profile is destroyed last: WeightEntry#after_destroy
  # syncs its weight back onto the (still cached, in-memory) profile, so
  # destroying it any earlier raises on a stale destroyed record.
  def reset_all_data!
    transaction do
      days.destroy_all
      recipes.destroy_all
      shopping_lists.destroy_all
      food_labels.destroy_all
      foods.destroy_all
      day_food_groups.destroy_all
      weight_entries.destroy_all
      body_measurements.destroy_all
      exercise_favorites.destroy_all
      workout_programs.destroy_all
      exercises.destroy_all
      profile.destroy
      create_profile!
    end
  end

  private

  def create_profile
    create_profile!
  end

  def generate_session_token
    SecureRandom.hex(20)
  end
end
