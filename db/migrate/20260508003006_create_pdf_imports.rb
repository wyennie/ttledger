class CreatePdfImports < ActiveRecord::Migration[8.0]
  def change
    create_table :pdf_imports do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :original_filename
      t.jsonb :extracted_pages
      t.jsonb :draft_payload
      t.text :error_message

      t.timestamps
    end
    add_index :pdf_imports, [ :campaign_id, :created_at ]
  end
end
