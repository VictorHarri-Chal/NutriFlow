class AddSourceToFoods < ActiveRecord::Migration[8.0]
  def up
    add_column :foods, :source, :string, default: "manual", null: false

    execute <<~SQL
      UPDATE foods SET source = 'off'
        WHERE off_id IS NOT NULL AND off_id != '';
      UPDATE foods SET source = 'ciqual'
        WHERE (off_id IS NULL OR off_id = '')
          AND micronutrients != '{}'::jsonb;
    SQL
  end

  def down
    remove_column :foods, :source
  end
end
