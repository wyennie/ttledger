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

ActiveRecord::Schema[8.0].define(version: 2025_01_14_184545) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "armors", force: :cascade do |t|
    t.integer "ac_bonus"
    t.integer "check_penalty"
    t.integer "speed_penalty"
    t.string "fumble_die"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "campaign_invitations", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.integer "sender_id", null: false
    t.integer "receiver_id", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_campaign_invitations_on_campaign_id"
    t.index ["receiver_id"], name: "index_campaign_invitations_on_receiver_id"
    t.index ["sender_id"], name: "index_campaign_invitations_on_sender_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "characters", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "user_id", null: false
    t.integer "campaign_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "occupation"
    t.string "title"
    t.string "character_class"
    t.string "alignment"
    t.integer "speed"
    t.integer "level"
    t.integer "xp"
    t.integer "ac"
    t.text "background"
    t.text "notes"
    t.text "short_term_goals"
    t.text "medium_term_goals"
    t.text "long_term_goals"
    t.string "languages", default: "Common Tongue"
    t.text "lucky_sign"
    t.integer "initiative"
    t.string "action_dice", default: "d20"
    t.integer "attack_bonus", default: 0
    t.string "crit_die", default: "d4"
    t.string "crit_table", default: "Table I"
    t.string "fumble_die", default: "d4"
    t.integer "reflex", default: 0
    t.integer "fortitude", default: 0
    t.integer "willpower", default: 0
    t.integer "current_hp", default: 0, null: false
    t.integer "max_hp", default: 0, null: false
    t.integer "current_strength", default: 10, null: false
    t.integer "max_strength", default: 10, null: false
    t.integer "current_agility", default: 10, null: false
    t.integer "max_agility", default: 10, null: false
    t.integer "current_stamina", default: 10, null: false
    t.integer "max_stamina", default: 10, null: false
    t.integer "current_personality", default: 10, null: false
    t.integer "max_personality", default: 10, null: false
    t.integer "current_intelligence", default: 10, null: false
    t.integer "max_intelligence", default: 10, null: false
    t.integer "current_luck", default: 10, null: false
    t.integer "max_luck", default: 10, null: false
    t.index ["campaign_id"], name: "index_characters_on_campaign_id"
    t.index ["user_id"], name: "index_characters_on_user_id"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.text "content"
    t.string "role"
    t.bigint "page_id", null: false
    t.bigint "campaign_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_chat_messages_on_campaign_id"
    t.index ["page_id"], name: "index_chat_messages_on_page_id"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "containers", force: :cascade do |t|
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.integer "sender_id"
    t.integer "receiver_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "items", force: :cascade do |t|
    t.string "name"
    t.string "weight", default: "0.0"
    t.string "value", default: "0"
    t.integer "count", default: 1
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "item_type_type", null: false
    t.integer "item_type_id", null: false
    t.text "description", default: ""
    t.integer "container_id"
    t.index ["character_id"], name: "index_items_on_character_id"
    t.index ["container_id"], name: "index_items_on_container_id"
    t.index ["item_type_type", "item_type_id"], name: "index_items_on_item_type"
  end

  create_table "pages", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "body"
    t.bigint "parent_id"
    t.bigint "campaign_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_pages_on_campaign_id"
    t.index ["parent_id"], name: "index_pages_on_parent_id"
  end

  create_table "roles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "campaign_id", null: false
    t.integer "role_type", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_roles_on_campaign_id"
    t.index ["user_id"], name: "index_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.string "username"
    t.datetime "confirmed_at"
    t.string "confirmation_token"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "weapons", force: :cascade do |t|
    t.string "damage"
    t.integer "range"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "campaign_invitations", "campaigns"
  add_foreign_key "campaign_invitations", "users", column: "receiver_id"
  add_foreign_key "campaign_invitations", "users", column: "sender_id"
  add_foreign_key "characters", "campaigns"
  add_foreign_key "characters", "users"
  add_foreign_key "chat_messages", "campaigns"
  add_foreign_key "chat_messages", "pages"
  add_foreign_key "chat_messages", "users"
  add_foreign_key "items", "characters"
  add_foreign_key "items", "items", column: "container_id"
  add_foreign_key "pages", "campaigns"
  add_foreign_key "pages", "pages", column: "parent_id"
  add_foreign_key "roles", "campaigns"
  add_foreign_key "roles", "users"
end
