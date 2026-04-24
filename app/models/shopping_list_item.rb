class ShoppingListItem < ApplicationRecord
  CATEGORIES = %w[proteins grains vegetables fruits dairy beverages condiments other].freeze

  belongs_to :shopping_list
  belongs_to :food, optional: true

  validates :name, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true

  scope :unchecked, -> { where(checked: false) }
  scope :checked,   -> { where(checked: true)  }
end
