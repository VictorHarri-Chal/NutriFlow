class DayFoodGroupsController < ApplicationController
  include SettingsDataLoadable
  include ActionView::RecordIdentifier

  before_action :set_day_food_group, only: [:edit, :update, :destroy]

  def create
    @day_food_group = current_user.day_food_groups.build(day_food_group_params)

    if @day_food_group.save
      redirect_to setting_path(tab: 'day_food_groups')
    else
      load_settings_data(active_tab: 'day_food_groups')
      render 'settings/show', status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @day_food_group.update(day_food_group_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@day_food_group), partial: "day_food_groups/day_food_group", locals: { day_food_group: @day_food_group }
          )
        end
        format.html { redirect_to setting_path(tab: 'day_food_groups') }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@day_food_group), partial: "day_food_groups/form", locals: { day_food_group: @day_food_group }
          ), status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
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
