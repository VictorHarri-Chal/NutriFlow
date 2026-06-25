class AddOpenFoodFactsToFoods < ActiveRecord::Migration[8.0]
  def change
    add_column :foods, :off_id, :string
    add_column :foods, :nutriscore_grade, :string
    add_column :foods, :nova_group, :integer
    add_index :foods, :off_id
  end
end
