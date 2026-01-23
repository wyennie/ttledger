class AddUserToMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :messages, :user, foreign_key: true, null: true
  end
end
