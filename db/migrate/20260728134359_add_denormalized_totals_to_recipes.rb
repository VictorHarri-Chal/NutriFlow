class AddDenormalizedTotalsToRecipes < ActiveRecord::Migration[8.0]
  TOTAL_COLUMNS = %i[
    total_calories total_proteins total_carbs total_fats total_sugars
    total_weight total_fiber total_saturated_fat total_salt
  ].freeze

  def up
    TOTAL_COLUMNS.each do |col|
      # precision 14 (not 10): grams_equivalent can reach 1e8 for a validated
      # 100000 kg item, and a recipe's summed calories can exceed 1e8 — decimal(10,2)
      # (~1e8 max) would raise PG::NumericValueOutOfRange on inputs the model accepts.
      add_column :recipes, col, :decimal, precision: 14, scale: 2, default: 0, null: false
    end

    # Backfill existing recipes from their current live computation.
    Recipe.reset_column_information
    Recipe.includes(recipe_items: :food).find_each(&:recompute_totals!)
  end

  def down
    TOTAL_COLUMNS.each { |col| remove_column :recipes, col }
  end
end
