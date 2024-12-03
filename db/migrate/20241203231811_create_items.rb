class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :name
      t.string :weight
      t.string :value
      t.integer :count
      t.references :character, null: false, foreign_key: true

      t.timestamps
    end
  end
end
