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

ActiveRecord::Schema[7.2].define(version: 2025_04_25_064157) do
  create_table "booking_audit_logs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "booking_id", null: false
    t.string "action"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_booking_audit_logs_on_booking_id"
    t.index ["user_id"], name: "index_booking_audit_logs_on_user_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "status"
    t.decimal "total_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.integer "capacity"
    t.decimal "price_per_hour"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "booking_id"
    t.index ["booking_id"], name: "index_rooms_on_booking_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "booking_audit_logs", "bookings"
  add_foreign_key "booking_audit_logs", "users"
  add_foreign_key "bookings", "users"
  add_foreign_key "rooms", "bookings"
end
