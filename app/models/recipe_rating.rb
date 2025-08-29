class RecipeRating < ApplicationRecord
  belongs_to :recipe
  belongs_to :user

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :recipe_id, uniqueness: { message: "Cette recette a déjà une notation" }

  scope :ordered, -> { order(created_at: :desc) }
end
