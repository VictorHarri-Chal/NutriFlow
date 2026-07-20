class CreateFastingSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :fasting_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string   :protocol, null: false, default: "sixteen_eight"
      t.datetime :started_at, null: false
      t.datetime :ended_at

      t.timestamps
    end

    add_index :fasting_sessions, :user_id, unique: true,
      where: "ended_at IS NULL", name: "index_one_active_fasting_session_per_user"
  end
end
