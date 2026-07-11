class ShoppingListsController < ApplicationController
  include LoadsShoppingListState

  before_action :set_shopping_list, only: [:show, :clear_checked, :clear_all, :destroy, :archive]
  before_action :set_archived_list, only: [:merge_into_current, :replace_current]
  before_action :redirect_if_archived, only: [:show]

  def index
    redirect_to current_user.active_shopping_list
  end

  def show
    set_list_state
    set_foods_json
  end

  # Pas de page dédiée : l'historique n'existe qu'en modale, paginée 5 par page.
  def history
    @archived_lists = current_user.shopping_lists.archived.includes(:shopping_list_items)
    @pagy, @archived_lists = pagy(@archived_lists, items: 5)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to shopping_lists_path }
    end
  end

  def suggestions_preview
    @shopping_list = current_user.active_shopping_list
    set_suggestions
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to shopping_lists_path }
    end
  end

  def archive
    @shopping_list.archive!(name: params[:name])
    redirect_to shopping_lists_path, notice: t("views.shopping_lists.archived")
  end

  def merge_into_current
    current_user.active_shopping_list.merge_from!(@archived_list)
    redirect_to shopping_lists_path, notice: t("views.shopping_lists.merged_from_archive")
  end

  def replace_current
    current_user.active_shopping_list.replace_with!(@archived_list)
    redirect_to shopping_lists_path, notice: t("views.shopping_lists.replaced_from_archive")
  end

  def week_preview
    @candidates = week_missing_foods
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to shopping_lists_path }
    end
  end

  def generate_from_week
    @shopping_list = current_user.active_shopping_list
    selected_ids   = Array(params[:food_ids]).map(&:to_i)
    candidates     = week_missing_foods.values.select { |c| selected_ids.include?(c[:food].id) }

    candidates.each do |c|
      @shopping_list.add_or_merge_item(food: c[:food], name: c[:food].name, quantity: c[:quantity], category: c[:category])
    end

    @added_count = candidates.size
    set_list_state
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @shopping_list, notice: t("views.shopping_lists.items_added", count: @added_count) }
    end
  end

  def clear_checked
    checked_items = @shopping_list.shopping_list_items.checked
    food_ids = checked_items.where.not(food_id: nil).pluck(:food_id)
    current_user.foods.where(id: food_ids).update_all(in_pantry: true) if food_ids.any?
    checked_items.delete_all
    set_list_state
    flash.now[:notice] = t("views.shopping_lists.cleared_checked")
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @shopping_list, notice: flash.now[:notice] }
    end
  end

  def clear_all
    @shopping_list.shopping_list_items.delete_all
    set_list_state
    flash.now[:notice] = t("views.shopping_lists.cleared_all")
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @shopping_list, notice: flash.now[:notice] }
    end
  end

  def destroy
    @shopping_list.destroy!
    redirect_to shopping_lists_path, notice: t("views.shopping_lists.deleted")
  end

  private

  def set_shopping_list
    @shopping_list = current_user.shopping_lists.find(params[:id])
  end

  def set_archived_list
    @archived_list = current_user.shopping_lists.archived.find(params[:id])
  end

  def redirect_if_archived
    redirect_to shopping_lists_path if @shopping_list.archived?
  end

  # Agrège les aliments in_pantry: false consommés (DayFood direct ou via une
  # recette) sur les 7 derniers jours. Retourne un Hash food_id => { food:,
  # quantity:, category: } — recalculé côté serveur à chaque appel, jamais
  # accepté depuis les params (voir generate_from_week).
  def week_missing_foods
    days = current_user.days
             .where(date: 6.days.ago.to_date..Date.current)
             .includes(day_foods: :food, day_recipes: { recipe: { recipe_items: :food } })

    agg = Hash.new { |h, k| h[k] = { food: nil, grams: 0.0, unit: "g", category: nil } }

    days.each do |day|
      day.day_foods.each do |df|
        next if df.food.in_pantry

        entry = agg[df.food.id]
        entry[:food] ||= df.food
        entry[:category] ||= df.food.category
        entry[:grams] += df.quantity.to_f
      end

      day.day_recipes.each do |dr|
        dr.recipe.recipe_items.each do |ri|
          next if ri.food.in_pantry

          entry = agg[ri.food.id]
          entry[:food] ||= ri.food
          entry[:category] ||= ri.food.category
          entry[:unit] = "mL" if %w[mL L].include?(ri.unit)
          entry[:grams] += ri.grams_equivalent * dr.gram_factor
        end
      end
    end

    result = agg.transform_values do |v|
      qty = v[:grams].round(1)
      v.merge(quantity: "#{qty % 1 == 0 ? qty.to_i : qty} #{v[:unit]}")
    end
    result.sort_by { |_id, v| v[:food].name }.to_h
  end
end
