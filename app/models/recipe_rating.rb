class RecipeRating < ApplicationRecord
  belongs_to :recipe
  belongs_to :user

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :recipe_id, uniqueness: { scope: :user_id }

  scope :ordered, -> { order(created_at: :desc) }
end
