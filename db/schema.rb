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

ActiveRecord::Schema.define(version: 20150814212503) do

  create_table "corporate_communications", force: :cascade do |t|
    t.string   "email_id"
    t.string   "title"
    t.datetime "date_sent"
    t.string   "category"
    t.text     "body"
  end

  add_index "corporate_communications", ["category"], name: "i_cor_com_cat"

  create_table "job_statuses", force: :cascade do |t|
    t.integer  "user_id",             limit: 16,  precision: 38
    t.string   "job_id"
    t.integer  "status",              limit: 16,  precision: 38, default: 0
    t.datetime "finished_at"
    t.string   "result_file_name"
    t.string   "result_content_type"
    t.integer  "result_file_size",    limit: 16,  precision: 38
    t.datetime "result_updated_at"
    t.boolean  "no_download",         limit: nil,                default: false
  end

  add_index "job_statuses", ["finished_at"], name: "i_job_statuses_finished_at"
  add_index "job_statuses", ["job_id"], name: "index_job_statuses_on_job_id", unique: true
  add_index "job_statuses", ["status"], name: "index_job_statuses_on_status"

  create_table "users", force: :cascade do |t|
    t.string   "username",                                         default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer  "sign_in_count",          limit: 16, precision: 38, default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ldap_domain"
    t.datetime "terms_accepted_at"
  end

  add_index "users", ["reset_password_token"], name: "i_users_reset_password_token", unique: true
  add_index "users", ["terms_accepted_at"], name: "i_users_terms_accepted_at"
  add_index "users", ["username"], name: "index_users_on_username", unique: true

end
