class CreateWeapons < ActiveRecord::Migration[8.0]
  def change
    create_table :weapons do |t|
      t.string :damage
      t.integer :range

      t.timestamps
    end
  end
end
