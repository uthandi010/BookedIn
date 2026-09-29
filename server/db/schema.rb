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

ActiveRecord::Schema[8.1].define(version: 2026_09_29_060916) do
  create_table "appointments", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "service_id", null: false
    t.integer "staff_user_id"
    t.string "customer_name", null: false
    t.string "customer_email", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "starts_at"], name: "index_appointments_on_business_id_and_starts_at"
    t.index ["business_id"], name: "index_appointments_on_business_id"
    t.index ["service_id"], name: "index_appointments_on_service_id"
    t.index ["staff_user_id"], name: "index_appointments_on_staff_user_id"
  end

  create_table "business_hours", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "day_of_week", null: false
    t.integer "start_minute", null: false
    t.integer "end_minute", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "day_of_week"], name: "index_business_hours_on_business_id_and_day_of_week", unique: true
    t.index ["business_id"], name: "index_business_hours_on_business_id"
  end

  create_table "business_members", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "user_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "user_id"], name: "index_business_members_on_business_id_and_user_id", unique: true
    t.index ["business_id"], name: "index_business_members_on_business_id"
    t.index ["user_id"], name: "index_business_members_on_user_id"
  end

  create_table "businesses", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_businesses_on_owner_id"
    t.index ["slug"], name: "index_businesses_on_slug", unique: true
  end

  create_table "services", force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name", null: false
    t.integer "duration_minutes", null: false
    t.integer "price_cents"
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_services_on_business_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "appointments", "businesses"
  add_foreign_key "appointments", "services"
  add_foreign_key "business_hours", "businesses"
  add_foreign_key "business_members", "businesses"
  add_foreign_key "business_members", "users"
  add_foreign_key "businesses", "users", column: "owner_id"
  add_foreign_key "services", "businesses"
end
