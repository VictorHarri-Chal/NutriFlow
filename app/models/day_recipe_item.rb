class DayRecipeItem < ApplicationRecord
  include HasFoodSnapshot
  include ValidatesSharedOwner

  belongs_to :day_recipe

  validates :quantity, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: HasFoodSnapshot::MAX_QUANTITY }
  # food_id peut être NULL après suppression d'un aliment (FK on_delete: :nullify) :
  # un item détaché reste valide tant qu'il a son snapshot figé. On n'exige un
  # food_id que pour un item neuf (pas encore de snapshot à figer).
  validates :food_id, presence: true, unless: -> { food_snapshot.present? }
  validates :unit, inclusion: { in: HasFoodSnapshot::UNITS }
  validates_shared_owner :food, owner: -> { day_recipe&.day }
  validate :quantity_at_least_one_gram_equivalent

  private

  def quantity_at_least_one_gram_equivalent
    return if quantity.blank? || errors[:quantity].any?
    errors.add(:quantity, :greater_than_or_equal_to, count: 1) if grams_equivalent < 1
  end
end
