class FoodLabel < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :foods, join_table: 'food_labels_foods'

  validates :name, presence: true, length: { maximum: 20 }
  validates :name, uniqueness: { scope: :user_id }

  scope :for_user, ->(user) { where(user: user) }
end
