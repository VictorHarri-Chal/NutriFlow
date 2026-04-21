# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_04_21_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "day_food_groups", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_day_food_groups_on_user_id"
  end

  create_table "day_foods", force: :cascade do |t|
    t.bigint "day_id", null: false
    t.bigint "food_id", null: false
    t.decimal "quantity", default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "day_food_group_id"
    t.index ["day_food_group_id"], name: "index_day_foods_on_day_food_group_id"
    t.index ["day_id", "food_id"], name: "index_day_foods_on_day_id_and_food_id"
    t.index ["day_id"], name: "index_day_foods_on_day_id"
    t.index ["food_id"], name: "index_day_foods_on_food_id"
  end

  create_table "day_recipes", force: :cascade do |t|
    t.bigint "day_id", null: false
    t.bigint "recipe_id", null: false
    t.bigint "day_food_group_id"
    t.decimal "quantity", precision: 8, scale: 2
    t.boolean "use_recipe_quantity", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day_food_group_id"], name: "index_day_recipes_on_day_food_group_id"
    t.index ["day_id"], name: "index_day_recipes_on_day_id"
    t.index ["recipe_id"], name: "index_day_recipes_on_recipe_id"
  end

  create_table "days", force: :cascade do |t|
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.text "note"
    t.integer "energy_level"
    t.integer "mood"
    t.integer "sleep_quality"
    t.integer "water_ml", default: 0, null: false
    t.integer "steps"
    t.index ["date", "user_id"], name: "index_days_on_date_and_user_id", unique: true
    t.index ["user_id"], name: "index_days_on_user_id"
  end

  create_table "exercise_favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "exercise_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_exercise_favorites_on_exercise_id"
    t.index ["user_id", "exercise_id"], name: "index_exercise_favorites_on_user_id_and_exercise_id", unique: true
    t.index ["user_id"], name: "index_exercise_favorites_on_user_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.string "exercise_id", null: false
    t.string "name", null: false
    t.string "body_part"
    t.string "equipment"
    t.string "gif_url"
    t.string "target_muscle"
    t.jsonb "secondary_muscles", default: [], null: false
    t.text "instructions"
    t.bigint "custom_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "difficulty"
    t.string "category"
    t.string "gif_status"
    t.text "name_fr"
    t.text "description_fr"
    t.text "instructions_fr"
    t.index ["body_part"], name: "index_exercises_on_body_part"
    t.index ["custom_user_id"], name: "index_exercises_on_custom_user_id"
    t.index ["exercise_id"], name: "index_exercises_on_exercise_id", unique: true
    t.index ["name"], name: "index_exercises_on_name"
    t.index ["target_muscle"], name: "index_exercises_on_target_muscle"
  end

  create_table "food_labels", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color"
    t.index ["name", "user_id"], name: "index_food_labels_on_name_and_user_id", unique: true
    t.index ["user_id"], name: "index_food_labels_on_user_id"
  end

  create_table "food_labels_foods", id: false, force: :cascade do |t|
    t.bigint "food_label_id", null: false
    t.bigint "food_id", null: false
    t.index ["food_id"], name: "index_food_labels_foods_on_food_id"
    t.index ["food_label_id", "food_id"], name: "index_food_labels_foods_on_food_label_id_and_food_id", unique: true
    t.index ["food_label_id"], name: "index_food_labels_foods_on_food_label_id"
  end

  create_table "foods", force: :cascade do |t|
    t.string "name", null: false
    t.string "brand"
    t.decimal "fats", null: false
    t.decimal "carbs", null: false
    t.decimal "sugars", null: false
    t.decimal "proteins", null: false
    t.decimal "calories", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "favorite", default: false, null: false
    t.index ["brand"], name: "index_foods_on_brand"
    t.index ["name"], name: "index_foods_on_name"
    t.index ["user_id"], name: "index_foods_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.decimal "weight"
    t.decimal "height"
    t.integer "age"
    t.string "gender"
    t.string "goal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "water_goal_ml", default: 2000, null: false
    t.decimal "goal_weight", precision: 5, scale: 2
    t.string "job_activity_level", default: "light_activity", null: false
    t.integer "default_daily_steps", default: 6000, null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "recipe_items", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "food_id", null: false
    t.decimal "quantity", default: "100.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["food_id"], name: "index_recipe_items_on_food_id"
    t.index ["recipe_id", "food_id"], name: "index_recipe_items_on_recipe_id_and_food_id"
    t.index ["recipe_id"], name: "index_recipe_items_on_recipe_id"
  end

  create_table "recipe_ratings", force: :cascade do |t|
    t.integer "rating", null: false
    t.text "comment"
    t.bigint "recipe_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "user_id"], name: "index_recipe_ratings_on_recipe_id_and_user_id", unique: true
    t.index ["recipe_id"], name: "index_recipe_ratings_on_recipe_id"
    t.index ["user_id"], name: "index_recipe_ratings_on_user_id"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "check_rating_range"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "name", null: false
    t.text "instructions"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "favorite", default: false, null: false
    t.index ["name", "user_id"], name: "index_recipes_on_name_and_user_id"
    t.index ["user_id"], name: "index_recipes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale", default: "fr", null: false
    t.boolean "show_day_note", default: true, null: false
    t.boolean "show_workout_section", default: true, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "weight_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.decimal "weight_kg", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "date"], name: "index_weight_entries_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_weight_entries_on_user_id"
  end

  create_table "workout_sessions", force: :cascade do |t|
    t.bigint "day_id", null: false
    t.integer "duration_minutes"
    t.integer "rpe"
    t.text "notes"
    t.integer "calories_burned"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day_id"], name: "index_workout_sessions_on_day_id"
  end

  create_table "workout_sets", force: :cascade do |t|
    t.bigint "workout_session_id", null: false
    t.bigint "exercise_id", null: false
    t.decimal "weight_kg", precision: 6, scale: 2
    t.integer "reps"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_workout_sets_on_exercise_id"
    t.index ["workout_session_id", "position"], name: "index_workout_sets_on_workout_session_id_and_position"
    t.index ["workout_session_id"], name: "index_workout_sets_on_workout_session_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "day_food_groups", "users"
  add_foreign_key "day_foods", "day_food_groups"
  add_foreign_key "day_foods", "days"
  add_foreign_key "day_foods", "foods"
  add_foreign_key "day_recipes", "day_food_groups"
  add_foreign_key "day_recipes", "days"
  add_foreign_key "day_recipes", "recipes"
  add_foreign_key "days", "users"
  add_foreign_key "exercise_favorites", "exercises"
  add_foreign_key "exercise_favorites", "users"
  add_foreign_key "food_labels", "users"
  add_foreign_key "food_labels_foods", "food_labels"
  add_foreign_key "food_labels_foods", "foods"
  add_foreign_key "foods", "users"
  add_foreign_key "profiles", "users"
  add_foreign_key "recipe_items", "foods"
  add_foreign_key "recipe_items", "recipes"
  add_foreign_key "recipe_ratings", "recipes"
  add_foreign_key "recipe_ratings", "users"
  add_foreign_key "recipes", "users"
  add_foreign_key "weight_entries", "users"
  add_foreign_key "workout_sessions", "days"
  add_foreign_key "workout_sets", "exercises"
  add_foreign_key "workout_sets", "workout_sessions"
end
