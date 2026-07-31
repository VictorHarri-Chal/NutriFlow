class AddUniqueIndexToRecipesUserLowerName < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # Enforces at the DB level the model's `uniqueness: { scope: :user_id,
  # case_sensitive: false }`, closing the concurrent-insert race. The functional
  # (user_id, lower(name)) index also serves user_id-prefix lookups, so the old
  # non-unique (name, user_id) index is dropped as redundant.
  #
  # Prerequisite in production: deduplicate any existing case-insensitive
  # homonyms per user before this runs, or the concurrent build fails.
  def up
    add_index :recipes, "user_id, lower(name)", unique: true,
              name: "index_recipes_on_user_id_and_lower_name", algorithm: :concurrently
    remove_index :recipes, name: "index_recipes_on_name_and_user_id", algorithm: :concurrently
  end

  def down
    add_index :recipes, [:name, :user_id],
              name: "index_recipes_on_name_and_user_id", algorithm: :concurrently
    remove_index :recipes, name: "index_recipes_on_user_id_and_lower_name", algorithm: :concurrently
  end
end
