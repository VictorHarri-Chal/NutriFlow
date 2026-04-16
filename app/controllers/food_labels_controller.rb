class FoodLabelsController < ApplicationController
  before_action :set_food_label, only: [:destroy]

  def create
    @food_label = current_user.food_labels.build(food_label_params)

    if @food_label.save
      redirect_to setting_path(tab: 'food_labels')
    else
      @food_labels    = current_user.food_labels.includes(:foods)
      @day_food_groups = current_user.day_food_groups.includes(:day_foods)
      @day_food_group  = DayFoodGroup.new
      @minimum_password_length = User.password_length.min
      @active_tab = 'food_labels'
      render 'settings/show', status: :unprocessable_entity
    end
  end

  def destroy
    @food_label.destroy
    redirect_to setting_path(tab: 'food_labels')
  end

  private

  def set_food_label
    @food_label = current_user.food_labels.find(params[:id])
  end

  def food_label_params
    params.require(:food_label).permit(:name, :color)
  end
end
