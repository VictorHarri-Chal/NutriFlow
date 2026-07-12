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

  has_one  :profile,        dependent: :destroy
  has_many :foods,          dependent: :destroy
  has_many :days,           dependent: :destroy
  has_many :day_food_groups, dependent: :destroy
  has_many :food_labels,    dependent: :destroy
  has_many :recipes,        dependent: :destroy
  has_many :weight_entries,       dependent: :destroy
  has_many :exercise_favorites,   dependent: :destroy
  has_many :favorited_exercises,  through: :exercise_favorites, source: :exercise
  has_many :workout_programs,     dependent: :destroy
  has_many :shopping_lists,       dependent: :destroy

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

  private

  def create_profile
    create_profile!
  end

  def generate_session_token
    SecureRandom.hex(20)
  end
end
