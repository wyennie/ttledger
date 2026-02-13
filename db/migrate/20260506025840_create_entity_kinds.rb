class CreateEntityKinds < ActiveRecord::Migration[8.0]
  def change
    create_table :entity_kinds do |t|
      t.string :name, null: false
      t.references :campaign, null: false, foreign_key: true

      t.timestamps
    end
    add_index :entity_kinds, [ :campaign_id, :name ], unique: true
  end
end
