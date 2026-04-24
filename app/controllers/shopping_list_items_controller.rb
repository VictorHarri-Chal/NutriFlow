class ShoppingListItemsController < ApplicationController
  before_action :set_shopping_list

  def create
    p       = params.fetch(:shopping_list_item, {})
    name    = p[:name].to_s.strip
    category = p[:category].presence
    food    = nil

    if p[:food_id].present?
      food     = current_user.foods.find_by(id: p[:food_id])
      name     = food.name if food
      category ||= food.category if food
    end

    quantity = if params[:quantity_value].present?
      unit = params[:quantity_unit].presence || "g"
      "#{params[:quantity_value]} #{unit}"
    end

    if name.blank?
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("shopping_list_add_form", partial: "shopping_lists/add_form", locals: { shopping_list: @shopping_list, foods_json: foods_json_for_autocomplete }) }
        format.html { redirect_to @shopping_list }
      end
      return
    end

    _item, status = @shopping_list.add_or_merge_item(food: food, name: name, quantity: quantity, category: category)
    flash.now[:notice] = if status == :merged
      t("controllers.shopping_list_items.merged", name: name)
    else
      t("controllers.shopping_list_items.created", name: name)
    end
    set_list_state
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @shopping_list }
    end
  end

  def update
    @item = @shopping_list.shopping_list_items.find(params[:id])
    @item.update!(item_params)
    set_list_state
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @shopping_list }
    end
  end

  def destroy
    @item = @shopping_list.shopping_list_items.find(params[:id])
    @item.destroy!
    set_list_state
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @shopping_list }
    end
  end

  private

  def set_shopping_list
    @shopping_list = current_user.shopping_lists.find(params[:shopping_list_id])
  end

  def set_list_state
    @items_by_category = @shopping_list.items_by_category
    @unchecked_count   = @shopping_list.shopping_list_items.unchecked.count
    @has_checked       = @shopping_list.shopping_list_items.checked.exists?
    @has_items         = @shopping_list.shopping_list_items.exists?
  end

  def foods_json_for_autocomplete
    current_user.foods.order(:name)
      .select(:id, :name, :category, :favorite)
      .as_json(only: [:id, :name, :category, :favorite])
  end

  def item_params
    # food_id n'est pas dans les permitted params — il est vérifié manuellement
    params.require(:shopping_list_item).permit(:name, :quantity, :checked, :category)
  end
end
