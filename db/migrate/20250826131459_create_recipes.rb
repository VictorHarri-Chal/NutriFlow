class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :name, null: false
      t.text :instructions
      t.bigint :user_id, null: false
      t.timestamps
    end

    add_index :recipes, [:name, :user_id]
    add_foreign_key :recipes, :users
  end
end
