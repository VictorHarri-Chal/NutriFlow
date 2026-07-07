class Api::V1::RecipeItemsController < Api::V1::BaseController
  before_action :set_recipe
  before_action :set_recipe_item, only: [:update, :destroy]

  def create
    @recipe_item = @recipe.recipe_items.build(recipe_item_params)
    if @recipe_item.save
      render json: recipe_item_json(@recipe_item), status: :created
    else
      render json: { errors: @recipe_item.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @recipe_item.update(recipe_item_params)
      render json: recipe_item_json(@recipe_item)
    else
      render json: { errors: @recipe_item.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe_item.destroy
    render json: {}, status: :no_content
  end

  private

  def set_recipe
    @recipe = current_user.recipes.find(params[:recipe_id])
  end

  def set_recipe_item
    @recipe_item = @recipe.recipe_items.find(params[:id])
  end

  def recipe_item_params
    params.permit(:food_id, :quantity, :unit)
  end

  def recipe_item_json(item)
    {
      id:              item.id,
      food_id:         item.food_id,
      food_name:       item.food.name,
      quantity:        item.quantity,
      unit:            item.unit,
      total_calories:  item.total_calories,
      total_proteins:  item.total_proteins,
      total_carbs:     item.total_carbs,
      total_fats:      item.total_fats
    }
  end
end
