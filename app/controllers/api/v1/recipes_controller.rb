class Api::V1::RecipesController < Api::V1::BaseController
  before_action :set_recipe, only: [:show, :update, :destroy, :toggle_favorite, :add_to_shopping_list]

  def index
    scope = current_user.recipes
    scope = scope.search_by_name(params[:query]) if params[:query].present?
    scope = scope.where(favorite: true) if params[:favorites] == "true"
    scope = scope.order(created_at: :desc)

    @pagy, @recipes = pagy(scope, items: 25)
    render :index
  end

  def show
    render :show
  end

  def create
    @recipe = current_user.recipes.build(recipe_params)
    if @recipe.save
      render :show, status: :created
    else
      render json: { errors: @recipe.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @recipe.update(recipe_params)
      render :show
    else
      render json: { errors: @recipe.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    render json: {}, status: :no_content
  end

  def toggle_favorite
    @recipe.update!(favorite: !@recipe.favorite)
    render json: { favorite: @recipe.favorite }
  end

  def add_to_shopping_list
    list = current_user.shopping_lists.order(created_at: :asc).first_or_create!(
      name: "Ma liste"
    )

    @recipe.recipe_items.includes(:food).each do |item|
      food = item.food
      list.add_or_merge_item(
        food:     food,
        name:     food.name,
        quantity: "#{item.grams_equivalent.round} g",
        category: food.category
      )
    end

    render json: { message: "Recette ajoutée à la liste." }
  end

  private

  def set_recipe
    @recipe = current_user.recipes.includes(recipe_items: :food, recipe_ratings: {}).find(params[:id])
  end

  def recipe_params
    params.permit(:name, :instructions, :favorite)
  end
end
