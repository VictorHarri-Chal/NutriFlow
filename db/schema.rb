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

ActiveRecord::Schema[8.0].define(version: 2026_07_14_104845) do
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

  create_table "body_measurements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.decimal "waist_cm", precision: 5, scale: 2
    t.decimal "hips_cm", precision: 5, scale: 2
    t.decimal "chest_cm", precision: 5, scale: 2
    t.decimal "biceps_cm", precision: 5, scale: 2
    t.decimal "thighs_cm", precision: 5, scale: 2
    t.decimal "calves_cm", precision: 5, scale: 2
    t.decimal "neck_cm", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "date"], name: "index_body_measurements_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_body_measurements_on_user_id"
  end

  create_table "cardio_blocks", force: :cascade do |t|
    t.bigint "cardio_session_id", null: false
    t.string "machine"
    t.integer "duration_minutes"
    t.decimal "speed_kmh", precision: 4, scale: 1
    t.integer "incline_percent"
    t.integer "resistance_level"
    t.decimal "distance_km", precision: 5, scale: 2
    t.integer "calories_burned"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cardio_session_id"], name: "index_cardio_blocks_on_cardio_session_id"
  end

  create_table "cardio_sessions", force: :cascade do |t|
    t.bigint "day_id", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day_id"], name: "index_cardio_sessions_on_day_id"
  end

  create_table "ciqual_foods", force: :cascade do |t|
    t.string "alim_code", null: false
    t.string "name", null: false
    t.string "food_group"
    t.decimal "calories", precision: 6, scale: 2, default: "0.0"
    t.decimal "proteins", precision: 6, scale: 2, default: "0.0"
    t.decimal "carbs", precision: 6, scale: 2, default: "0.0"
    t.decimal "fats", precision: 6, scale: 2, default: "0.0"
    t.decimal "sugars", precision: 6, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "fiber", precision: 6, scale: 2
    t.decimal "saturated_fat", precision: 6, scale: 2
    t.decimal "salt", precision: 6, scale: 2
    t.jsonb "micronutrients", default: {}
    t.index ["alim_code"], name: "index_ciqual_foods_on_alim_code", unique: true
    t.index ["name"], name: "index_ciqual_foods_on_name"
  end

  create_table "day_food_groups", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "user_id"], name: "index_day_food_groups_on_name_and_user_id", unique: true
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
    t.string "category"
    t.boolean "in_pantry", default: true, null: false
    t.string "off_id"
    t.string "nutriscore_grade"
    t.integer "nova_group"
    t.decimal "fiber", precision: 6, scale: 2
    t.decimal "saturated_fat", precision: 6, scale: 2
    t.decimal "salt", precision: 6, scale: 2
    t.string "ecoscore_grade"
    t.string "allergens", default: [], array: true
    t.string "traces", default: [], array: true
    t.jsonb "micronutrients", default: {}
    t.string "source", default: "manual", null: false
    t.string "additives", default: [], null: false, array: true
    t.string "labels", default: [], null: false, array: true
    t.text "ingredients_text"
    t.index ["brand"], name: "index_foods_on_brand"
    t.index ["name"], name: "index_foods_on_name"
    t.index ["off_id"], name: "index_foods_on_off_id"
    t.index ["user_id", "category"], name: "index_foods_on_user_id_and_category"
    t.index ["user_id", "favorite"], name: "index_foods_on_user_id_and_favorite"
    t.index ["user_id", "in_pantry"], name: "index_foods_on_user_id_and_in_pantry"
    t.index ["user_id", "name"], name: "index_foods_on_user_id_and_name_unique", unique: true
    t.index ["user_id"], name: "index_foods_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.decimal "weight"
    t.decimal "height"
    t.string "gender"
    t.string "goal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "water_goal_ml", default: 2000, null: false
    t.decimal "goal_weight", precision: 5, scale: 2
    t.string "job_activity_level", default: "light_activity", null: false
    t.integer "default_daily_steps", default: 6000, null: false
    t.decimal "goal_rate_kg_per_week", precision: 4, scale: 2, default: "0.0", null: false
    t.date "date_of_birth"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "program_days", force: :cascade do |t|
    t.bigint "workout_program_id", null: false
    t.integer "day_of_week", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration_minutes"
    t.text "notes"
    t.index ["workout_program_id", "day_of_week"], name: "index_program_days_on_workout_program_id_and_day_of_week", unique: true
    t.index ["workout_program_id"], name: "index_program_days_on_workout_program_id"
  end

  create_table "program_exercise_sets", force: :cascade do |t|
    t.bigint "program_exercise_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "reps_target", null: false
    t.decimal "weight_target", precision: 6, scale: 2
    t.integer "rpe"
    t.string "set_types", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_exercise_id", "position"], name: "idx_on_program_exercise_id_position_76c2d97a5b"
    t.index ["program_exercise_id"], name: "index_program_exercise_sets_on_program_exercise_id"
  end

  create_table "program_exercises", force: :cascade do |t|
    t.bigint "program_day_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "sets", default: 3, null: false
    t.integer "reps_target", default: 10, null: false
    t.decimal "weight_target", precision: 6, scale: 2
    t.integer "rest_seconds"
    t.integer "position", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_program_exercises_on_exercise_id"
    t.index ["program_day_id", "position"], name: "index_program_exercises_on_program_day_id_and_position"
    t.index ["program_day_id"], name: "index_program_exercises_on_program_day_id"
  end

  create_table "recipe_items", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "food_id", null: false
    t.decimal "quantity", default: "100.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unit", default: "g", null: false
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

  create_table "shopping_list_items", force: :cascade do |t|
    t.bigint "shopping_list_id", null: false
    t.bigint "food_id"
    t.string "name", null: false
    t.string "quantity"
    t.boolean "checked", default: false, null: false
    t.integer "position", default: 0, null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["food_id"], name: "index_shopping_list_items_on_food_id"
    t.index ["shopping_list_id", "position"], name: "index_shopping_list_items_on_shopping_list_id_and_position"
    t.index ["shopping_list_id"], name: "index_shopping_list_items_on_shopping_list_id"
  end

  create_table "shopping_lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", default: "Ma liste", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "archived_at"
    t.index ["user_id", "archived_at"], name: "index_shopping_lists_on_user_id_and_archived_at"
    t.index ["user_id"], name: "index_shopping_lists_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
    t.boolean "show_cardio_section", default: true, null: false
    t.boolean "show_water_tracking", default: true, null: false
    t.boolean "show_tdee_breakdown", default: true, null: false
    t.boolean "show_weight_tracking", default: true, null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "time_zone", default: "Europe/Paris", null: false
    t.string "session_token", null: false
    t.boolean "show_body_measurements", default: true, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
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

  create_table "workout_programs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "split_type", default: "custom", null: false
    t.boolean "is_active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "is_active"], name: "index_workout_programs_on_user_id_and_is_active"
    t.index ["user_id"], name: "index_workout_programs_on_user_id"
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
    t.integer "rest_seconds"
    t.text "notes"
    t.boolean "is_pr", default: false, null: false
    t.index ["exercise_id"], name: "index_workout_sets_on_exercise_id"
    t.index ["workout_session_id", "position"], name: "index_workout_sets_on_workout_session_id_and_position"
    t.index ["workout_session_id"], name: "index_workout_sets_on_workout_session_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "body_measurements", "users"
  add_foreign_key "cardio_blocks", "cardio_sessions"
  add_foreign_key "cardio_sessions", "days"
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
  add_foreign_key "program_days", "workout_programs"
  add_foreign_key "program_exercise_sets", "program_exercises"
  add_foreign_key "program_exercises", "exercises"
  add_foreign_key "program_exercises", "program_days"
  add_foreign_key "recipe_items", "foods"
  add_foreign_key "recipe_items", "recipes"
  add_foreign_key "recipe_ratings", "recipes"
  add_foreign_key "recipe_ratings", "users"
  add_foreign_key "recipes", "users"
  add_foreign_key "shopping_list_items", "foods"
  add_foreign_key "shopping_list_items", "shopping_lists"
  add_foreign_key "shopping_lists", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "weight_entries", "users"
  add_foreign_key "workout_programs", "users"
  add_foreign_key "workout_sessions", "days"
  add_foreign_key "workout_sets", "exercises"
  add_foreign_key "workout_sets", "workout_sessions"
end
