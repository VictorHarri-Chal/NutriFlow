class ShoppingListItem < ApplicationRecord
  include ValidatesSharedOwner

  CATEGORIES = %w[proteins grains vegetables fruits dairy beverages condiments supplements other].freeze

  belongs_to :shopping_list
  belongs_to :food, optional: true

  validates :name, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  validates_shared_owner :food, owner: :shopping_list, if: :food_id?

  scope :unchecked, -> { where(checked: false) }
  scope :checked,   -> { where(checked: true)  }

  before_create :assign_position

  private

  # Place un nouvel item en fin de sa catégorie plutôt qu'à position 0 —
  # sinon tout ajout après un premier réordonnancement manuel sauterait
  # en tête de catégorie de façon incohérente.
  def assign_position
    return if position != 0

    scope = shopping_list.shopping_list_items.where("COALESCE(category, 'other') = ?", category.presence || "other")
    self.position = (scope.maximum(:position) || -1) + 1
  end
end
