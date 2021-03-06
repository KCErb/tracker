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

ActiveRecord::Schema.define(version: 20141121154201) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "comments", force: true do |t|
    t.integer  "member_id"
    t.integer  "household_id"
    t.boolean  "private"
    t.text     "body"
    t.text     "commenter_name"
    t.text     "commenter_calling"
    t.text     "commenter_lds_id"
    t.text     "viewed_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["household_id"], name: "index_comments_on_household_id", using: :btree
  add_index "comments", ["member_id"], name: "index_comments_on_member_id", using: :btree

  create_table "households", force: true do |t|
    t.text     "lds_id"
    t.date     "moved_in"
    t.text     "move_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "members", force: true do |t|
    t.integer  "household_id"
    t.text     "lds_id"
    t.text     "organizations"
    t.date     "moved_in"
    t.text     "move_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "members", ["household_id"], name: "index_members_on_household_id", using: :btree

  create_table "tag_histories", force: true do |t|
    t.integer  "member_id"
    t.integer  "household_id"
    t.integer  "tag_id"
    t.text     "added_by"
    t.text     "removed_by"
    t.text     "added_at"
    t.text     "removed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tag_histories", ["household_id"], name: "index_tag_histories_on_household_id", using: :btree
  add_index "tag_histories", ["member_id"], name: "index_tag_histories_on_member_id", using: :btree
  add_index "tag_histories", ["tag_id"], name: "index_tag_histories_on_tag_id", using: :btree

  create_table "tags", force: true do |t|
    t.text     "body"
    t.text     "organization"
    t.text     "color"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.text     "lds_id"
    t.text     "name"
    t.text     "calling"
    t.text     "organization"
    t.text     "filters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "progress_message"
    t.float    "table_progress"
    t.boolean  "table_ready"
    t.text     "table"
  end

end
