class AddOffProductFieldsToFoods < ActiveRecord::Migration[8.0]
  def change
    add_column :foods, :additives,        :string, array: true, default: [], null: false
    add_column :foods, :labels,           :string, array: true, default: [], null: false
    add_column :foods, :ingredients_text, :text
  end
end
