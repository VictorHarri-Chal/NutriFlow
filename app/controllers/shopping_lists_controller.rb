class ShoppingListsController < ApplicationController
  before_action :set_shopping_list, only: [:show, :clear_checked, :clear_all, :destroy]

  def index
    list = current_user.shopping_lists.order(created_at: :asc).first_or_create!(
      name: t("views.shopping_lists.default_name")
    )
    redirect_to list
  end

  def show
    @items_by_category = @shopping_list.items_by_category
    @unchecked_count   = @shopping_list.shopping_list_items.unchecked.count
    @has_checked       = @shopping_list.shopping_list_items.checked.exists?
    @has_items         = @shopping_list.shopping_list_items.exists?
    @foods_json        = current_user.foods.order(:name)
                                     .select(:id, :name, :category, :favorite)
                                     .as_json(only: [:id, :name, :category, :favorite])
  end

  def clear_checked
    @shopping_list.shopping_list_items.checked.delete_all
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

  def set_list_state
    @items_by_category = @shopping_list.items_by_category
    @unchecked_count   = @shopping_list.shopping_list_items.unchecked.count
    @has_checked       = @shopping_list.shopping_list_items.checked.exists?
    @has_items         = @shopping_list.shopping_list_items.exists?
  end
end
