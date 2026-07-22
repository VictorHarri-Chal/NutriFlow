class AddSectionOrderToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :section_order, :string, array: true,
      default: %w[food water workout cardio fasting day_note], null: false
  end
end
