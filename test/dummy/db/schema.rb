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

ActiveRecord::Schema[8.1].define(version: 2026_06_17_000000) do
  create_table "currencies", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "subunit", default: 2, null: false
    t.string "symbol", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_currencies_on_code", unique: true
  end

  create_table "financial_transactions", force: :cascade do |t|
    t.integer "amount"
    t.datetime "created_at", null: false
    t.string "currency", limit: 3
    t.datetime "date"
    t.string "description"
    t.datetime "updated_at", null: false
  end

  create_table "offers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.decimal "price_amount"
    t.string "price_currency"
    t.string "product"
    t.datetime "updated_at", null: false
  end

  create_table "simple_offers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.decimal "discount"
    t.decimal "price"
    t.string "product"
    t.datetime "updated_at", null: false
  end
end
