class DayFoodGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_day_food_group, only: [:destroy]

  def create
    @day_food_group = current_user.day_food_groups.build(day_food_group_params)

    if @day_food_group.save
      redirect_to setting_path(tab: 'day_food_groups')
    else
      @day_food_groups = current_user.day_food_groups.includes(:day_foods)
      @active_tab = 'day_food_groups'
      render 'settings/show', status: :unprocessable_entity
    end
  end

  def destroy
    @day_food_group.destroy
    redirect_to setting_path(tab: 'day_food_groups')
  end

  private

  def set_day_food_group
    @day_food_group = current_user.day_food_groups.find(params[:id])
  end

  def day_food_group_params
    params.require(:day_food_group).permit(:name)
  end
end
