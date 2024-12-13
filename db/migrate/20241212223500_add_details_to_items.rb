class AddDetailsToItems < ActiveRecord::Migration[8.0]
  def change
    change_column_default :items, :count, 1
    change_column_default :items, :value, 0
    change_column_default :items, :weight, 0.0

    add_column :items, :description, :text, default: ""
  end
end
