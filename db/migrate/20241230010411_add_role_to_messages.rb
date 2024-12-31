class AddRoleToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :role, :string
  end
end
