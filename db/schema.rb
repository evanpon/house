# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160204191636) do

  create_table "details", force: :cascade do |t|
    t.integer  "home_id",    limit: 4
    t.string   "name",       limit: 255
    t.string   "value",      limit: 2000
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "details", ["home_id", "name"], name: "index_details_on_home_id_and_name", unique: true, using: :btree

  create_table "homes", force: :cascade do |t|
    t.string   "address",    limit: 255
    t.integer  "listing_id", limit: 4
    t.string   "price",      limit: 255
    t.string   "notes",      limit: 2000
    t.integer  "ranking",    limit: 4
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "value",      limit: 4,    default: 0
    t.boolean  "active",                  default: false
  end

  add_index "homes", ["listing_id"], name: "index_homes_on_listing_id", unique: true, using: :btree
  add_index "homes", ["value"], name: "index_homes_on_value", using: :btree

  create_table "scorecards", force: :cascade do |t|
    t.integer  "home_id",    limit: 4
    t.integer  "kitchen",    limit: 4, default: 0
    t.integer  "light",      limit: 4, default: 0
    t.integer  "yard",       limit: 4, default: 0
    t.integer  "location",   limit: 4, default: 0
    t.integer  "potential",  limit: 4, default: 0
    t.integer  "layout",     limit: 4, default: 0
    t.integer  "charm",      limit: 4, default: 0
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "scorecards", ["home_id"], name: "index_scorecards_on_home_id", using: :btree

end
