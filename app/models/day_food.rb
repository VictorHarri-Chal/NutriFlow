class DayFood < ApplicationRecord
  include HasFoodQuantity
  include ValidatesSharedOwner

  belongs_to :day
  belongs_to :day_food_group, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validate :day_food_group_belongs_to_user, if: -> { day_food_group_id.present? && day.present? }
  validates_shared_owner :food, owner: :day

  # day_foods n'a pas de colonne `unit` (toujours en grammes) — HasFoodQuantity
  # en a besoin pour son calcul générique de grams_equivalent.
  def unit = "g"

  private

  def day_food_group_belongs_to_user
    unless day.user.day_food_groups.exists?(day_food_group_id)
      errors.add(:day_food_group, :invalid)
    end
  end

  public

  # Pour la cohérence avec DayRecipe
  def food_name
    food.name
  end

  def display_quantity
    "#{quantity} g"
  end
end
