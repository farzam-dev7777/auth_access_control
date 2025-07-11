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

ActiveRecord::Schema[8.0].define(version: 2025_07_11_111855) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id"
    t.string "action", null: false
    t.jsonb "metadata", default: {}
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "performed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "action"], name: "index_activity_logs_on_organization_id_and_action"
    t.index ["organization_id", "performed_at"], name: "index_activity_logs_on_organization_id_and_performed_at"
    t.index ["organization_id"], name: "index_activity_logs_on_organization_id"
    t.index ["user_id", "performed_at"], name: "index_activity_logs_on_user_id_and_performed_at"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "membership_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.string "status", default: "pending"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_membership_requests_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_membership_requests_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_membership_requests_on_user_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.integer "org_type"
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parental_consents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "parent_email", null: false
    t.string "consent_token", null: false
    t.datetime "consent_requested_at", null: false
    t.datetime "consented_at"
    t.datetime "expires_at", null: false
    t.boolean "consented", default: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consent_token"], name: "index_parental_consents_on_consent_token", unique: true
    t.index ["parent_email"], name: "index_parental_consents_on_parent_email"
    t.index ["user_id"], name: "index_parental_consents_on_user_id"
  end

  create_table "participation_rules", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "rule_type", null: false
    t.jsonb "conditions", default: {}
    t.jsonb "actions", default: {}
    t.boolean "active", default: true
    t.integer "priority", default: 0
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "active"], name: "index_participation_rules_on_organization_id_and_active"
    t.index ["organization_id", "rule_type"], name: "index_participation_rules_on_organization_id_and_rule_type"
    t.index ["organization_id"], name: "index_participation_rules_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.date "date_of_birth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "suspended", default: false
    t.datetime "suspended_at"
    t.text "suspended_reason"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["suspended"], name: "index_users_on_suspended"
  end

  add_foreign_key "activity_logs", "organizations"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "membership_requests", "organizations"
  add_foreign_key "membership_requests", "users"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "parental_consents", "users"
  add_foreign_key "participation_rules", "organizations"
end
