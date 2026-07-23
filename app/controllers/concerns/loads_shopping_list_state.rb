module LoadsShoppingListState
  extend ActiveSupport::Concern

  private

  def set_list_state
    @items_by_category = @shopping_list.items_by_category
    @unchecked_count    = @shopping_list.unchecked_count
    @has_checked        = @shopping_list.has_checked?
    @has_items          = @shopping_list.has_items?
  end

  def set_foods_json
    @foods_json = current_user.foods.order(:name)
                              .select(:id, :name, :category, :favorite)
                              .as_json(only: [:id, :name, :category, :favorite])
  end

  def set_suggestions
    excluded = @shopping_list.shopping_list_items.where.not(food_id: nil).pluck(:food_id)
    @suggested_foods = Food.frequently_used(user: current_user, excluding_ids: excluded)
  end
end
