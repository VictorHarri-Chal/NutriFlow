class BackfillNutritionLogSnapshots < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    say_with_time "Backfill day_foods" do
      DayFood.includes(:food).find_each do |df|
        next if df.food.nil?
        df.update_columns(
          food_name:     df.food.name,
          food_snapshot: DayFood.build_food_snapshot(df.food)
        )
      end
    end

    say_with_time "Backfill day_recipe_items" do
      DayRecipeItem.includes(:food).find_each do |item|
        next if item.food.nil?
        item.update_columns(
          food_name:     item.food.name,
          food_snapshot: DayRecipeItem.build_food_snapshot(item.food)
        )
      end
    end

    say_with_time "Backfill + matérialisation day_recipes" do
      DayRecipe.includes(:recipe, :day_recipe_items).find_each do |dr|
        recipe = dr.recipe
        dr.update_columns(recipe_name: recipe&.name)

        # Déjà matérialisée → items déjà backfillés ci-dessus.
        next if dr.day_recipe_items.any?
        next if recipe.nil?

        total  = recipe.recipe_items.sum(&:grams_equivalent).to_f
        eff    = dr.read_attribute(:use_recipe_quantity) ? total : dr.read_attribute(:quantity).to_f
        factor = total.zero? ? 1.0 : (eff / total)
        factor = 1.0 if factor <= 0

        recipe.recipe_items.each do |ri|
          DayRecipeItem.create!(
            day_recipe:    dr,
            food:          ri.food,
            quantity:      (ri.grams_equivalent * factor).round(1),
            unit:          "g",
            food_name:     ri.food.name,
            food_snapshot: DayRecipeItem.build_food_snapshot(ri.food)
          )
        end
      end
    end
  end

  def down
    DayFood.update_all(food_name: nil, food_snapshot: nil)
    DayRecipeItem.update_all(food_name: nil, food_snapshot: nil)
    DayRecipe.update_all(recipe_name: nil)
  end
end
