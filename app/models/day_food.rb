class DayFood < ApplicationRecord
  include HasFoodSnapshot
  include ValidatesSharedOwner

  belongs_to :day
  belongs_to :day_food_group, optional: true

  validates :quantity, presence: true,
            numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: HasFoodSnapshot::MAX_QUANTITY }
  validate :day_food_group_belongs_to_user, if: -> { day_food_group_id.present? && day.present? }
  validates_shared_owner :food, owner: :day

  # day_foods n'a pas de colonne `unit` (toujours en grammes) — le concern en a
  # besoin pour grams_equivalent.
  def unit = "g"

  def display_quantity
    "#{quantity} g"
  end

  # Log détaché : l'aliment a été supprimé de la banque (food_id nullifié), le
  # snapshot + le nom figé subsistent.
  def detached? = food_id.nil? && food_name.present?

  private

  def day_food_group_belongs_to_user
    unless day.user.day_food_groups.exists?(day_food_group_id)
      errors.add(:day_food_group, :invalid)
    end
  end
end
