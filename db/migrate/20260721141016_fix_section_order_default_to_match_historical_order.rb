class FixSectionOrderDefaultToMatchHistoricalOrder < ActiveRecord::Migration[8.0]
  OLD_DEFAULT = %w[food water workout cardio fasting day_note].freeze
  NEW_DEFAULT = %w[water workout cardio fasting food day_note].freeze

  def up
    change_column_default :users, :section_order, from: OLD_DEFAULT, to: NEW_DEFAULT
    User.where(section_order: OLD_DEFAULT).update_all(section_order: NEW_DEFAULT)
  end

  def down
    change_column_default :users, :section_order, from: NEW_DEFAULT, to: OLD_DEFAULT
    User.where(section_order: NEW_DEFAULT).update_all(section_order: OLD_DEFAULT)
  end
end
