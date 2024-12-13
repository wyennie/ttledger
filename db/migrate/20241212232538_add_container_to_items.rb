class AddContainerToItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :items, :container, foreign_key: { to_table: :items }, null: true
  end
end
