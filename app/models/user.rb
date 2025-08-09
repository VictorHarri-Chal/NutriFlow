class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :profile, dependent: :destroy
  has_many :foods, dependent: :destroy
  has_many :days, dependent: :destroy
  has_many :day_food_groups, dependent: :destroy

  after_create :create_profile

  private

  def create_profile
    create_profile!
  end
end
