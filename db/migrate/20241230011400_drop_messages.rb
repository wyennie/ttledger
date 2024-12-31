class DropMessages < ActiveRecord::Migration[8.0]
  def change
    drop_table :messages
  end
end
