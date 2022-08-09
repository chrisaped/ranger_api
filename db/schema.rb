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

ActiveRecord::Schema[7.0].define(version: 2022_08_09_113831) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "orders", force: :cascade do |t|
    t.integer "side"
    t.string "symbol"
    t.json "raw_order"
    t.integer "quantity"
    t.decimal "price"
    t.bigint "position_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position_id"], name: "index_orders_on_position_id"
  end

  create_table "positions", force: :cascade do |t|
    t.integer "status"
    t.integer "initial_quantity"
    t.string "symbol"
    t.integer "side"
    t.integer "current_quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "initial_price"
  end

  create_table "targets", force: :cascade do |t|
    t.integer "quantity"
    t.decimal "price"
    t.float "multiplier"
    t.bigint "position_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "fulfilled", default: false
    t.index ["position_id"], name: "index_targets_on_position_id"
  end

  add_foreign_key "orders", "positions"
  add_foreign_key "targets", "positions"
end
