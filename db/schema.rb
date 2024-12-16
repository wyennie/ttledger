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

ActiveRecord::Schema[8.0].define(version: 2024_12_16_212054) do
  create_table "armors", force: :cascade do |t|
    t.integer "ac_bonus"
    t.integer "check_penalty"
    t.integer "speed_penalty"
    t.string "fumble_die"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "character_derived_stats", force: :cascade do |t|
    t.integer "character_id", null: false
    t.integer "initiative"
    t.string "action_dice"
    t.string "attack_dice"
    t.string "crit_die"
    t.string "crit_table"
    t.string "fumble_die"
    t.string "fumble_table"
    t.integer "reflex"
    t.integer "fortitude"
    t.integer "willpower"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "hp", default: 1, null: false
    t.integer "max_hp", default: 1, null: false
    t.index ["character_id"], name: "index_character_derived_stats_on_character_id"
  end

  create_table "character_stats", force: :cascade do |t|
    t.integer "character_id", null: false
    t.integer "strength_current"
    t.integer "strength_max"
    t.integer "strength_modifier"
    t.integer "agility_current"
    t.integer "agility_max"
    t.integer "agility_modifier"
    t.integer "stamina_current"
    t.integer "stamina_max"
    t.integer "stamina_modifier"
    t.integer "personality_current"
    t.integer "personality_max"
    t.integer "personality_modifier"
    t.integer "intelligence_current"
    t.integer "intelligence_max"
    t.integer "intelligence_modifier"
    t.integer "luck_current"
    t.integer "luck_max"
    t.integer "luck_modifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_character_stats_on_character_id"
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
    t.index ["campaign_id"], name: "index_characters_on_campaign_id"
    t.index ["user_id"], name: "index_characters_on_user_id"
  end

  create_table "containers", force: :cascade do |t|
    t.integer "capacity"
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

  add_foreign_key "character_derived_stats", "characters"
  add_foreign_key "character_stats", "characters"
  add_foreign_key "characters", "campaigns"
  add_foreign_key "characters", "users"
  add_foreign_key "items", "characters"
  add_foreign_key "items", "items", column: "container_id"
  add_foreign_key "roles", "campaigns"
  add_foreign_key "roles", "users"
end
