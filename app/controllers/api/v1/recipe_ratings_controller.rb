class Api::V1::RecipeRatingsController < Api::V1::BaseController
  before_action :set_recipe
  before_action :set_rating, only: [:update, :destroy]

  def create
    existing = @recipe.recipe_ratings.find_by(user: current_user)
    if existing
      render json: { errors: { base: ["Vous avez déjà noté cette recette."] } }, status: :unprocessable_entity
      return
    end

    @rating = @recipe.recipe_ratings.build(rating_params.merge(user: current_user))
    if @rating.save
      render json: rating_json(@rating), status: :created
    else
      render json: { errors: @rating.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @rating.update(rating_params)
      render json: rating_json(@rating)
    else
      render json: { errors: @rating.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @rating.destroy
    render json: {}, status: :no_content
  end

  private

  def set_recipe
    @recipe = current_user.recipes.find(params[:recipe_id])
  end

  def set_rating
    @rating = @recipe.recipe_ratings.find_by!(id: params[:id], user: current_user)
  end

  def rating_params
    params.permit(:rating, :comment)
  end

  def rating_json(r)
    { id: r.id, rating: r.rating, comment: r.comment }
  end
end
