class CreatePages < ActiveRecord::Migration[8.0]
  def change
    create_table :pages do |t|
      t.string :title
      t.string :slug
      t.text :body
      t.references :parent, null: true, foreign_key: {to_table: :pages}
      t.references :campaign, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
