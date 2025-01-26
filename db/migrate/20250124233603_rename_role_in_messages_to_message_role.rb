class RenameRoleInMessagesToMessageRole < ActiveRecord::Migration[8.0]
  def change
    rename_column :messages, :role, :message_role
  end
end
