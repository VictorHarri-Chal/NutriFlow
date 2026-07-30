class AddCachedTotalsToDays < ActiveRecord::Migration[8.0]
  CACHED_COLUMNS = %i[cached_calories cached_proteins cached_carbs cached_fats cached_sugars].freeze

  def up
    CACHED_COLUMNS.each do |col|
      # precision 14 mirrors recipes.total_* — a day can sum several large entries.
      add_column :days, col, :decimal, precision: 14, scale: 2, default: 0, null: false
    end

    Day.reset_column_information
    Day.find_each(&:recompute_totals!)
  end

  def down
    CACHED_COLUMNS.each { |col| remove_column :days, col }
  end
end
