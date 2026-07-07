class Api::V1::ShoppingListItemsController < Api::V1::BaseController
  before_action :set_shopping_list
  before_action :set_item, only: [:update, :destroy]

  def create
    food = nil
    if params[:food_id].present?
      food = current_user.foods.find_by(id: params[:food_id])
    end

    item, _status = @shopping_list.add_or_merge_item(
      food:     food,
      name:     params[:name].to_s,
      quantity: params[:quantity],
      category: params[:category]
    )

    render json: item_json(item), status: :created
  end

  def update
    if @item.update(item_params)
      render json: item_json(@item)
    else
      render json: { errors: @item.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy
    render json: {}, status: :no_content
  end

  private

  def set_shopping_list
    @shopping_list = current_user.shopping_lists.find(params[:shopping_list_id])
  end

  def set_item
    @item = @shopping_list.shopping_list_items.find(params[:id])
  end

  def item_params
    params.permit(:name, :quantity, :checked, :category)
  end

  def item_json(item)
    {
      id:       item.id,
      food_id:  item.food_id,
      name:     item.name,
      quantity: item.quantity,
      checked:  item.checked,
      category: item.category,
      position: item.position
    }
  end
end
