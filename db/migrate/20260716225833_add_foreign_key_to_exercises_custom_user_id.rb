class AddForeignKeyToExercisesCustomUserId < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL
      UPDATE exercises
      SET custom_user_id = NULL
      WHERE custom_user_id IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM users WHERE users.id = exercises.custom_user_id)
    SQL

    add_foreign_key :exercises, :users, column: :custom_user_id
  end
end
