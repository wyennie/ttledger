class CreateCharacterDerivedStats < ActiveRecord::Migration[8.0]
  def change
    create_table :character_derived_stats do |t|
      t.references :character, null: false, foreign_key: true
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

      t.timestamps
    end
  end
end
