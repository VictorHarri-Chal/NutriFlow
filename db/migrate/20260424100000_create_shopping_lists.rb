class CreateShoppingLists < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false, default: "Ma liste"
      t.timestamps
    end
  end
end
