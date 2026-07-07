class User < ApplicationRecord
  AVAILABLE_LOCALES = %w[fr en].freeze

  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, :omniauthable,
         jwt_revocation_strategy: self,
         omniauth_providers: [:apple, :google_oauth2]

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
  has_many :identities,           dependent: :destroy

  after_create :create_profile

  private

  def create_profile
    create_profile!
  end
end
