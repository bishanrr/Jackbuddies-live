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

ActiveRecord::Schema[8.1].define(version: 2026_02_25_070500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "allowed_signup_names", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name", null: false
    t.datetime "updated_at", null: false
    t.index ["first_name"], name: "index_allowed_signup_names_on_first_name", unique: true
  end

  create_table "daily_match_entries", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.integer "match_no", null: false
    t.datetime "processed_at", null: false
    t.text "raw_text", null: false
    t.bigint "season_id", null: false
    t.datetime "updated_at", null: false
    t.string "winner_team_short_name", null: false
    t.index ["admin_user_id"], name: "index_daily_match_entries_on_admin_user_id"
    t.index ["season_id", "match_no", "processed_at"], name: "index_daily_match_entries_on_season_match_processed"
    t.index ["season_id"], name: "index_daily_match_entries_on_season_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "away_team_id", null: false
    t.datetime "created_at", null: false
    t.bigint "home_team_id", null: false
    t.datetime "match_datetime", null: false
    t.integer "match_no"
    t.bigint "season_id", null: false
    t.integer "stage", null: false
    t.integer "status", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "winner_team_id"
    t.index ["away_team_id"], name: "index_matches_on_away_team_id"
    t.index ["home_team_id"], name: "index_matches_on_home_team_id"
    t.index ["season_id", "match_datetime"], name: "index_matches_on_season_id_and_match_datetime"
    t.index ["season_id", "match_no"], name: "index_matches_on_season_id_and_match_no", unique: true, where: "(match_no IS NOT NULL)"
    t.index ["season_id"], name: "index_matches_on_season_id"
    t.index ["winner_team_id"], name: "index_matches_on_winner_team_id"
    t.check_constraint "home_team_id <> away_team_id", name: "check_matches_distinct_teams"
  end

  create_table "pick_audit_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "editor_admin_id", null: false
    t.bigint "from_team_id"
    t.bigint "match_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "pick_id"
    t.string "reason", null: false
    t.bigint "to_team_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["editor_admin_id"], name: "index_pick_audit_logs_on_editor_admin_id"
    t.index ["from_team_id"], name: "index_pick_audit_logs_on_from_team_id"
    t.index ["match_id"], name: "index_pick_audit_logs_on_match_id"
    t.index ["pick_id"], name: "index_pick_audit_logs_on_pick_id"
    t.index ["to_team_id"], name: "index_pick_audit_logs_on_to_team_id"
    t.index ["user_id"], name: "index_pick_audit_logs_on_user_id"
  end

  create_table "picks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "match_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_admin_id"
    t.bigint "user_id", null: false
    t.index ["match_id"], name: "index_picks_on_match_id"
    t.index ["team_id"], name: "index_picks_on_team_id"
    t.index ["updated_by_admin_id"], name: "index_picks_on_updated_by_admin_id"
    t.index ["user_id", "match_id"], name: "index_picks_on_user_id_and_match_id", unique: true
    t.index ["user_id"], name: "index_picks_on_user_id"
  end

  create_table "points_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_admin_id"
    t.integer "event_type", default: 0, null: false
    t.bigint "match_id"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "pick_id"
    t.integer "points", null: false
    t.string "reason", null: false
    t.bigint "season_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "void_reason"
    t.datetime "voided_at"
    t.bigint "voided_by_admin_id"
    t.bigint "voided_event_reference_id"
    t.index ["created_by_admin_id"], name: "index_points_events_on_created_by_admin_id"
    t.index ["match_id", "user_id"], name: "index_points_events_on_match_id_and_user_id"
    t.index ["match_id"], name: "index_points_events_on_match_id"
    t.index ["pick_id"], name: "index_points_events_on_pick_id"
    t.index ["season_id", "user_id"], name: "index_points_events_on_season_id_and_user_id"
    t.index ["season_id"], name: "index_points_events_on_season_id"
    t.index ["user_id", "match_id"], name: "index_points_events_on_import_user_match", unique: true, where: "((match_id IS NOT NULL) AND ((reason)::text = 'import'::text))"
    t.index ["user_id"], name: "index_points_events_on_user_id"
    t.index ["voided_by_admin_id"], name: "index_points_events_on_voided_by_admin_id"
    t.index ["voided_event_reference_id"], name: "index_points_events_on_voided_event_reference_id"
    t.check_constraint "points >= '-1000'::integer AND points <= 1000", name: "check_points_events_reasonable_range"
  end

  create_table "points_rules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "points_for_correct", null: false
    t.bigint "season_id", null: false
    t.integer "stage", null: false
    t.datetime "updated_at", null: false
    t.index ["season_id", "stage"], name: "index_points_rules_on_season_id_and_stage", unique: true
    t.index ["season_id"], name: "index_points_rules_on_season_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "default_lock_minutes", default: 10, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["year"], name: "index_seasons_on_year", unique: true
  end

  create_table "team_season_stats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "losses", default: 0, null: false
    t.integer "played", default: 0, null: false
    t.bigint "season_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.integer "wins", default: 0, null: false
    t.index ["season_id", "team_id"], name: "index_team_season_stats_on_season_id_and_team_id", unique: true
    t.index ["season_id"], name: "index_team_season_stats_on_season_id"
    t.index ["team_id"], name: "index_team_season_stats_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "short_name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
    t.index ["short_name"], name: "index_teams_on_short_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.text "denial_reason"
    t.datetime "denied_at"
    t.bigint "denied_by_id"
    t.string "display_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_users_on_approved_by_id"
    t.index ["denied_by_id"], name: "index_users_on_denied_by_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "daily_match_entries", "seasons"
  add_foreign_key "daily_match_entries", "users", column: "admin_user_id"
  add_foreign_key "matches", "seasons"
  add_foreign_key "matches", "teams", column: "away_team_id"
  add_foreign_key "matches", "teams", column: "home_team_id"
  add_foreign_key "matches", "teams", column: "winner_team_id"
  add_foreign_key "pick_audit_logs", "matches"
  add_foreign_key "pick_audit_logs", "picks"
  add_foreign_key "pick_audit_logs", "teams", column: "from_team_id"
  add_foreign_key "pick_audit_logs", "teams", column: "to_team_id"
  add_foreign_key "pick_audit_logs", "users"
  add_foreign_key "pick_audit_logs", "users", column: "editor_admin_id"
  add_foreign_key "picks", "matches"
  add_foreign_key "picks", "teams"
  add_foreign_key "picks", "users"
  add_foreign_key "picks", "users", column: "updated_by_admin_id"
  add_foreign_key "points_events", "matches"
  add_foreign_key "points_events", "picks"
  add_foreign_key "points_events", "seasons"
  add_foreign_key "points_events", "users"
  add_foreign_key "points_events", "users", column: "created_by_admin_id"
  add_foreign_key "points_events", "users", column: "voided_by_admin_id"
  add_foreign_key "points_rules", "seasons"
  add_foreign_key "team_season_stats", "seasons"
  add_foreign_key "team_season_stats", "teams"
  add_foreign_key "users", "users", column: "approved_by_id"
  add_foreign_key "users", "users", column: "denied_by_id"
end
