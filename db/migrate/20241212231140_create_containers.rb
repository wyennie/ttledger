class CreateContainers < ActiveRecord::Migration[8.0]
  def change
    create_table :containers do |t|
      t.integer :capacity

      t.timestamps
    end
  end
end
