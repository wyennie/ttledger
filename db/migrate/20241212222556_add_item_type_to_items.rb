class AddItemTypeToItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :items, :item_type, polymorphic: true, null: false
  end
end
