class CreateDataExports < ActiveRecord::Migration[8.0]
  def change
    create_table :data_exports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :categories, null: false, default: [], array: true
      t.string :period_kind, null: false, default: "all"
      t.date :date_from
      t.date :date_to
      t.text :error_message

      t.timestamps
    end
  end
end
