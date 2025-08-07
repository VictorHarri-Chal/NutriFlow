class FoodsController < ApplicationController
  before_action :set_food, only: [:edit, :update, :destroy]

  def index
    @foods = params[:query].then do |query|
      base_query = query.present? ? Food.search_by_name(query) : Food.all
      sort_foods(base_query)
    end
  end

  def new
    @food = Food.new
  end

  def create
    @food = Food.new(food_params)
    if @food.save
      redirect_to foods_path, notice: "Aliment créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @food.update(food_params)
      redirect_to foods_path, notice: "Aliment mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @food.destroy
    redirect_to foods_path, notice: "Aliment supprimé avec succès."
  end

  private

  def set_food
    @food = Food.find(params[:id])
  end

  def food_params
    params.require(:food).permit(:name, :brand, :fats, :carbs, :sugars, :proteins, :calories)
  end

  def sort_foods(base_query)
    allowed_fields = %w[name brand fats carbs sugars proteins calories]
    sort_by = allowed_fields.include?(params[:sort_by]) ? params[:sort_by] : 'name'
    direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'

    base_query.order(sort_by => direction)
  end
end
