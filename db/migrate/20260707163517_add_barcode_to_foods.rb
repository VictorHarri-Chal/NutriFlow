class AddBarcodeToFoods < ActiveRecord::Migration[8.0]
  def change
    add_column :foods, :barcode, :string
    add_index  :foods, [:user_id, :barcode]
  end
end
