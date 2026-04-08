class DayRecipe < ApplicationRecord
  belongs_to :day
  belongs_to :recipe
  belongs_to :day_food_group, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }, unless: :use_recipe_quantity?
  validates :recipe_id, presence: true
  validate :day_food_group_belongs_to_user, if: -> { day_food_group_id.present? && day.present? }

  private

  def day_food_group_belongs_to_user
    unless day.user.day_food_groups.exists?(day_food_group_id)
      errors.add(:day_food_group, :invalid)
    end
  end

  public

  def effective_quantity
    use_recipe_quantity? ? recipe.total_weight : quantity
  end

  def gram_factor
    total = recipe.total_weight.to_f
    return 0.0 if total.zero?

    effective_quantity / total
  end

  # Méthodes pour compatibilité avec DayFood
  def food
    recipe
  end

  def food_name
    recipe.name
  end

  def total_calories
    (recipe.total_calories * gram_factor).round(1)
  end

  def total_proteins
    (recipe.total_proteins * gram_factor).round(1)
  end

  def total_carbs
    (recipe.total_carbs * gram_factor).round(1)
  end

  def total_fats
    (recipe.total_fats * gram_factor).round(1)
  end

  def total_sugars
    (recipe.total_sugars * gram_factor).round(1)
  end

  def total_weight
    effective_quantity
  end

  # Pour l'affichage dans les composants
  def display_quantity
    "#{effective_quantity} g"
  end
end
