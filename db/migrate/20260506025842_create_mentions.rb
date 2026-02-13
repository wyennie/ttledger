class CreateMentions < ActiveRecord::Migration[8.0]
  def change
    create_table :mentions do |t|
      t.references :entity, null: false, foreign_key: true
      t.string :mentionable_type, null: false
      t.bigint :mentionable_id, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :mentions, [ :mentionable_type, :mentionable_id ]
    add_index :mentions, [ :entity_id, :mentionable_type ]
    add_index :mentions,
              [ :entity_id, :mentionable_type, :mentionable_id, :position ],
              unique: true,
              name: "index_mentions_uniqueness"
  end
end
