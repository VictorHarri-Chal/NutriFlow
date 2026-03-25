class DayRecipesController < ApplicationController
  include CalendarData

  before_action :set_day,        only: [:new, :create]
  before_action :set_day_recipe, only: [:edit, :update, :destroy]

  def new
    @day_recipe      = @day.day_recipes.build
    @day_food_groups = current_user.day_food_groups.order(:name)
    @recipes         = current_user.recipes.order(:name)
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
      @recipes         = current_user.recipes.order(:name)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("item_form", partial: "day_recipes/form", locals: { day: @day, day_recipe: @day_recipe, submit_text: "Ajouter" }) }
        format.html         { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @day_food_groups = current_user.day_food_groups.order(:name)
    @recipes         = current_user.recipes.order(:name)
  end

  def update
    if @day_recipe.update(day_recipe_params)
      redirect_to calendars_path(date: @day_recipe.day.date)
    else
      @day_food_groups = current_user.day_food_groups.order(:name)
      @recipes         = current_user.recipes.order(:name)
      render :edit, status: :unprocessable_entity
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
  end

  def day_recipe_params
    params.require(:day_recipe).permit(:recipe_id, :quantity, :day_food_group_id, :use_recipe_quantity)
  end
end
