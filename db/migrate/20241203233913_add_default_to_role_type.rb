class AddDefaultToRoleType < ActiveRecord::Migration[8.0]
  def change
    change_column_default :roles, :role_type, 1
    change_column_null :roles, :role_type, false, 1
  end
end
