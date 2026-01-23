class DropChatMessages < ActiveRecord::Migration[8.0]
  def up
    drop_table :chat_messages
  end

  def down
    create_table :chat_messages do |t|
      t.text :content
      t.string :role
      t.references :page, null: false, foreign_key: true
      t.references :campaign, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
