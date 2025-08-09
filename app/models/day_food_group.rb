class DayFoodGroup < ApplicationRecord
  belongs_to :user
  has_many :day_foods, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { scope: :user_id }

  scope :for_user, ->(user) { where(user: user) }
end
