class RecipeComment < ApplicationRecord
  belongs_to :recipe
  belongs_to :user

  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }

  scope :ordered, -> { order(created_at: :desc) }
end
