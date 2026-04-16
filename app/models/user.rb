class User < ApplicationRecord
  AVAILABLE_LOCALES = %w[fr en].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :locale, inclusion: { in: AVAILABLE_LOCALES }

  has_one  :profile,        dependent: :destroy
  has_many :foods,          dependent: :destroy
  has_many :days,           dependent: :destroy
  has_many :day_food_groups, dependent: :destroy
  has_many :food_labels,    dependent: :destroy
  has_many :recipes,        dependent: :destroy
  has_many :weight_entries, dependent: :destroy

  after_create :create_profile

  private

  def create_profile
    create_profile!
  end
end
