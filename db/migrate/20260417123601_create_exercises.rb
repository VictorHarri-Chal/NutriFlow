class CreateExercises < ActiveRecord::Migration[8.0]
  def change
    create_table :exercises do |t|
      t.string   :exercise_id,        null: false
      t.string   :name,               null: false
      t.string   :body_part
      t.string   :equipment
      t.string   :gif_url
      t.string   :target_muscle
      t.jsonb    :secondary_muscles,  null: false, default: []
      t.text     :instructions
      t.bigint   :custom_user_id

      t.timestamps
    end

    add_index :exercises, :exercise_id, unique: true
    add_index :exercises, :body_part
    add_index :exercises, :target_muscle
    add_index :exercises, :custom_user_id
    add_index :exercises, :name
  end
end
