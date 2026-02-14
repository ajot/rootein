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

ActiveRecord::Schema[8.0].define(version: 2026_02_14_115300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "completions", force: :cascade do |t|
    t.bigint "rootein_id", null: false
    t.date "completed_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rootein_id", "completed_on"], name: "index_completions_on_rootein_id_and_completed_on", unique: true
    t.index ["rootein_id"], name: "index_completions_on_rootein_id"
  end

  create_table "rooteins", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "completions", "rooteins"
end
