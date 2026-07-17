class AddForeignKeyToExercisesCustomUserId < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :exercises, :users, column: :custom_user_id
  end
end
