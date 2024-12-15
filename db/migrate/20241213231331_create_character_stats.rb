class CreateCharacterStats < ActiveRecord::Migration[8.0]
  def change
    create_table :character_stats do |t|
      t.references :character, null: false, foreign_key: true
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

      t.timestamps
    end
  end
end
