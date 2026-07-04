class Api::V1::FoodLabelsController < Api::V1::BaseController
  COLORS = %w[red orange amber yellow green teal blue violet].freeze

  before_action :set_food_label, only: [:show, :update, :destroy]

  def index
    @food_labels = current_user.food_labels.order(:name)
    render :index
  end

  def show
    render :show
  end

  def create
    @food_label = current_user.food_labels.build(food_label_params)
    if @food_label.save
      render :show, status: :created
    else
      render json: { errors: @food_label.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @food_label.update(food_label_params)
      render :show
    else
      render json: { errors: @food_label.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @food_label.destroy
    render json: {}, status: :no_content
  end

  private

  def set_food_label
    @food_label = current_user.food_labels.find(params[:id])
  end

  def food_label_params
    params.permit(:name, :color)
  end
end
