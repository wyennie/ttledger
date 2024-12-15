class AddHpToCharacterDerivedStats < ActiveRecord::Migration[8.0]
  def change
    add_column :character_derived_stats, :hp, :integer, default: 1, null: false
    add_column :character_derived_stats, :max_hp, :integer, default: 1, null: false
  end
end
