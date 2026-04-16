class AddColorToFoodLabels < ActiveRecord::Migration[8.0]
  def change
    add_column :food_labels, :color, :string
  end
end
