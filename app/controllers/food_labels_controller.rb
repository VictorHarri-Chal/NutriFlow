class FoodLabelsController < ApplicationController
  include SettingsDataLoadable
  include ActionView::RecordIdentifier

  before_action :set_food_label, only: [:edit, :update, :destroy]

  def create
    @food_label = current_user.food_labels.build(food_label_params)

    if @food_label.save
      redirect_to setting_path(tab: 'food_labels')
    else
      load_settings_data(active_tab: 'food_labels')
      render 'settings/show', status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @food_label.update(food_label_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@food_label), partial: "food_labels/food_label", locals: { food_label: @food_label }
          )
        end
        format.html { redirect_to setting_path(tab: 'food_labels') }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@food_label), partial: "food_labels/form", locals: { food_label: @food_label }
          ), status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
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
