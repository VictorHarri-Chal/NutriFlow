class Api::V1::ShoppingListsController < Api::V1::BaseController
  before_action :set_shopping_list, only: [:show, :update, :destroy, :clear_checked, :clear_all]

  def index
    @shopping_lists = current_user.shopping_lists.order(updated_at: :desc)
    render :index
  end

  def show
    render :show
  end

  def create
    @shopping_list = current_user.shopping_lists.build(shopping_list_params)
    if @shopping_list.save
      render :show, status: :created
    else
      render json: { errors: @shopping_list.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @shopping_list.update(shopping_list_params)
      render :show
    else
      render json: { errors: @shopping_list.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @shopping_list.destroy
    render json: {}, status: :no_content
  end

  def clear_checked
    checked_items = @shopping_list.shopping_list_items.where(checked: true).includes(:food)
    checked_items.each do |item|
      item.food&.update!(in_pantry: true)
    end
    checked_items.destroy_all
    render :show
  end

  def clear_all
    @shopping_list.shopping_list_items.destroy_all
    render :show
  end

  private

  def set_shopping_list
    @shopping_list = current_user.shopping_lists.find(params[:id])
  end

  def shopping_list_params
    params.permit(:name)
  end
end
