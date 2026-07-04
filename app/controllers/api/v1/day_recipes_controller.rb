class Api::V1::DayRecipesController < Api::V1::BaseController
  before_action :set_day
  before_action :set_day_recipe, only: [:update, :destroy]

  def create
    @day_recipe = @day.day_recipes.build(day_recipe_params)
    validate_day_food_group!
    if @day_recipe.save
      render json: day_recipe_json(@day_recipe), status: :created
    else
      render json: { errors: @day_recipe.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @day_recipe.update(day_recipe_params)
      render json: day_recipe_json(@day_recipe)
    else
      render json: { errors: @day_recipe.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @day_recipe.destroy
    render json: {}, status: :no_content
  end

  private

  def set_day
    @day = current_user.days.find_or_create_by!(date: params[:day_date])
  end

  def set_day_recipe
    @day_recipe = @day.day_recipes.find(params[:id])
  end

  def validate_day_food_group!
    return unless params[:day_food_group_id].present?
    group = current_user.day_food_groups.find_by(id: params[:day_food_group_id])
    @day_recipe.day_food_group = nil unless group
  end

  def day_recipe_params
    params.permit(:recipe_id, :quantity, :day_food_group_id, :use_recipe_quantity)
  end

  def day_recipe_json(dr)
    {
      id:                dr.id,
      recipe_id:         dr.recipe_id,
      recipe_name:       dr.recipe.name,
      quantity:          dr.quantity,
      use_recipe_quantity: dr.use_recipe_quantity,
      day_food_group_id: dr.day_food_group_id,
      total_calories:    dr.total_calories,
      total_proteins:    dr.total_proteins,
      total_carbs:       dr.total_carbs,
      total_fats:        dr.total_fats,
      total_sugars:      dr.total_sugars
    }
  end
end
