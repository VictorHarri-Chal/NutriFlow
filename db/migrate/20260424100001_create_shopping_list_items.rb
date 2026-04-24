class CreateShoppingListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_list_items do |t|
      t.references :shopping_list, null: false, foreign_key: true
      t.references :food,          null: true,  foreign_key: true
      t.string  :name,     null: false
      t.string  :quantity
      t.boolean :checked,  null: false, default: false
      t.integer :position, null: false, default: 0
      t.string  :category
      t.timestamps
    end

    add_index :shopping_list_items, [:shopping_list_id, :position]
  end
end
