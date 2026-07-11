class User < ApplicationRecord
  AVAILABLE_LOCALES = %w[fr en].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  validates :locale, inclusion: { in: AVAILABLE_LOCALES }

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

  def active_shopping_list
    shopping_lists.active.order(created_at: :asc).first_or_create!(
      name: I18n.t("views.shopping_lists.default_name")
    )
  end

  private

  def create_profile
    create_profile!
  end
end
