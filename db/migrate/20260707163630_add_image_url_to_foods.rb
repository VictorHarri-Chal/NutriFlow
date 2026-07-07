class AddImageUrlToFoods < ActiveRecord::Migration[8.0]
  def change
    add_column :foods, :image_url, :string
  end
end
