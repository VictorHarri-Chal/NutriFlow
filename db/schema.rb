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

ActiveRecord::Schema[8.0].define(version: 2025_08_07_153507) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "day_foods", force: :cascade do |t|
    t.bigint "day_id", null: false
    t.bigint "food_id", null: false
    t.decimal "quantity", default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day_id", "food_id"], name: "index_day_foods_on_day_id_and_food_id"
    t.index ["day_id"], name: "index_day_foods_on_day_id"
    t.index ["food_id"], name: "index_day_foods_on_food_id"
  end

  create_table "days", force: :cascade do |t|
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["date", "user_id"], name: "index_days_on_date_and_user_id", unique: true
    t.index ["user_id"], name: "index_days_on_user_id"
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
    t.index ["brand"], name: "index_foods_on_brand"
    t.index ["name"], name: "index_foods_on_name"
    t.index ["user_id"], name: "index_foods_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "day_foods", "days"
  add_foreign_key "day_foods", "foods"
  add_foreign_key "days", "users"
  add_foreign_key "foods", "users"
end
