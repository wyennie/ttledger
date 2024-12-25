class UpdateCharacterSchema < ActiveRecord::Migration[8.0]
  def change
    change_table :characters do |t|
      t.text :background
      t.text :notes
      t.text :short_term_goals
      t.text :medium_term_goals
      t.text :long_term_goals
      t.string :languages, default: "Common Tongue"
      t.text :lucky_sign
      t.integer :initiative
      t.string :action_dice, default: "d20"
      t.integer :attack_bonus, default: 0
      t.string :crit_die, default: "d4"
      t.string :crit_table, default: "Table I"
      t.string :fumble_die, default: "d4"
      t.integer :reflex, default: 0
      t.integer :fortitude, default: 0
      t.integer :willpower, default: 0
      t.integer :current_hp, default: 0, null: false
      t.integer :max_hp, default: 0, null: false
      t.integer :current_strength, default: 10, null: false
      t.integer :max_strength, default: 10, null: false
      t.integer :current_agility, default: 10, null: false
      t.integer :max_agility, default: 10, null: false
      t.integer :current_stamina, default: 10, null: false
      t.integer :max_stamina, default: 10, null: false
      t.integer :current_personality, default: 10, null: false
      t.integer :max_personality, default: 10, null: false
      t.integer :current_intelligence, default: 10, null: false
      t.integer :max_intelligence, default: 10, null: false
      t.integer :current_luck, default: 10, null: false
      t.integer :max_luck, default: 10, null: false
    end

    drop_table :character_derived_stats do |t|
      t.integer :character_id, null: false
      t.integer :initiative
      t.string :action_dice
      t.string :attack_dice
      t.string :crit_die
      t.string :crit_table
      t.string :fumble_die
      t.string :fumble_table
      t.integer :reflex
      t.integer :fortitude
      t.integer :willpower
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer :hp, default: 1, null: false
      t.integer :max_hp, default: 1, null: false
    end

    drop_table :character_stats do |t|
      t.integer :character_id, null: false
      t.integer :strength_current
      t.integer :strength_max
      t.integer :strength_modifier
      t.integer :agility_current
      t.integer :agility_max
      t.integer :agility_modifier
      t.integer :stamina_current
      t.integer :stamina_max
      t.integer :stamina_modifier
      t.integer :personality_current
      t.integer :personality_max
      t.integer :personality_modifier
      t.integer :intelligence_current
      t.integer :intelligence_max
      t.integer :intelligence_modifier
      t.integer :luck_current
      t.integer :luck_max
      t.integer :luck_modifier
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
