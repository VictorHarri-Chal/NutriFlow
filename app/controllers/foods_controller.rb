class FoodsController < ApplicationController
  before_action :set_food, only: [:edit, :update, :destroy]

  def index
    @q = current_user.foods.includes(:food_labels).ransack(params[:q])
    @foods = @q.result

    if params[:query].present?
      @foods = @foods.search_by_name(params[:query])
    end

    if params[:full_result] == "true"
      @foods = @foods.order(created_at: :desc)
      @pagy = nil
    else
      @pagy, @foods = pagy(@foods.order(created_at: :desc), items: 10)
    end
  end

  def new
    @food = current_user.foods.build
    @food_labels = current_user.food_labels
  end

  def create
    @food = current_user.foods.build(food_params)
    if @food.save
      redirect_to foods_path, notice: "Aliment créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @food_labels = current_user.food_labels
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
    @food = current_user.foods.find(params[:id])
  end

  def food_params
    params.require(:food).permit(:name, :brand, :fats, :carbs, :sugars, :proteins, :calories, food_label_ids: [])
  end
end
