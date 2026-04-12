class DayRecipesController < ApplicationController
  include CalendarData

  before_action :set_day,        only: [:new, :create]
  before_action :set_day_recipe, only: [:edit, :update, :destroy]

  def new
    group_id         = params.dig(:day_recipe, :day_food_group_id)
    @day_recipe      = @day.day_recipes.build(day_food_group_id: group_id)
    @day_food_groups = current_user.day_food_groups.order(:name)
    @recipes         = current_user.recipes.includes(recipe_items: :food).order(:name)
  end

  def create
    @day_recipe = @day.day_recipes.build(day_recipe_params)

    if @day_recipe.save
      load_calendar_data(@day)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to calendars_path(date: @day.date) }
      end
    else
      @day_food_groups = current_user.day_food_groups.order(:name)
      @recipes         = current_user.recipes.includes(recipe_items: :food).order(:name)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("item_form", partial: "day_recipes/form", locals: { day: @day, day_recipe: @day_recipe, submit_text: t("shared.add") }) }
        format.html         { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @day_food_groups = current_user.day_food_groups.order(:name)
    @recipes         = current_user.recipes.includes(recipe_items: :food).order(:name)
  end

  def update
    if @day_recipe.update(day_recipe_params)
      respond_to do |format|
        format.turbo_stream do
          load_calendar_data(@day)
        end
        format.html { redirect_to calendars_path(date: @day.date) }
      end
    else
      @day_food_groups = current_user.day_food_groups.order(:name)
      @recipes         = current_user.recipes.includes(recipe_items: :food).order(:name)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("item_form", partial: "day_recipes/form", locals: { day: @day, day_recipe: @day_recipe, submit_text: t("shared.update") }) }
        format.html         { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    day = @day_recipe.day
    @day_recipe.destroy
    load_calendar_data(day)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to calendars_path(date: day.date) }
    end
  end

  private

  def set_day
    @day = current_user.days.find(params[:day_id])
  end

  def set_day_recipe
    @day_recipe = DayRecipe.joins(:day).where(days: { user_id: current_user.id }).find(params[:id])
    @day = @day_recipe.day
  end

  def day_recipe_params
    params.require(:day_recipe).permit(:recipe_id, :quantity, :day_food_group_id, :use_recipe_quantity)
  end
end
