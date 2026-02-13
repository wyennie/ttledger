class CreateEntities < ActiveRecord::Migration[8.0]
  def change
    create_table :entities do |t|
      t.string :name, null: false
      t.string :slug
      t.text :summary
      t.references :campaign, null: false, foreign_key: true
      t.references :entity_kind, null: false, foreign_key: true
      t.references :bio_page, foreign_key: { to_table: :pages }

      t.timestamps
    end
    add_index :entities, [ :campaign_id, :name ]
  end
end
