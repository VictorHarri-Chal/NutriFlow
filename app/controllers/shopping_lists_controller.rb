class ShoppingListsController < ApplicationController
  include LoadsShoppingListState

  before_action :set_shopping_list, only: [:show, :clear_checked, :clear_all, :destroy]

  def index
    list = current_user.shopping_lists.order(created_at: :asc).first_or_create!(
      name: t("views.shopping_lists.default_name")
    )
    redirect_to list
  end

  def show
    set_list_state
    set_foods_json
  end

  def clear_checked
    checked_items = @shopping_list.shopping_list_items.checked
    food_ids = checked_items.where.not(food_id: nil).pluck(:food_id)
    current_user.foods.where(id: food_ids).update_all(in_pantry: true) if food_ids.any?
    checked_items.delete_all
    set_list_state
    flash.now[:notice] = t("views.shopping_lists.cleared_checked")
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @shopping_list, notice: flash.now[:notice] }
    end
  end

  def clear_all
    @shopping_list.shopping_list_items.delete_all
    set_list_state
    flash.now[:notice] = t("views.shopping_lists.cleared_all")
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @shopping_list, notice: flash.now[:notice] }
    end
  end

  def destroy
    @shopping_list.destroy!
    redirect_to shopping_lists_path, notice: t("views.shopping_lists.deleted")
  end

  private

  def set_shopping_list
    @shopping_list = current_user.shopping_lists.find(params[:id])
  end
end
