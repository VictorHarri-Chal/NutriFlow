class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :days, dependent: :destroy
  has_many :foods, dependent: :destroy
  has_many :day_foods, through: :days
end
