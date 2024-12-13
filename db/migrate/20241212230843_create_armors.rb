class CreateArmors < ActiveRecord::Migration[8.0]
  def change
    create_table :armors do |t|
      t.integer :ac_bonus
      t.integer :check_penalty
      t.integer :speed_penalty
      t.string :fumble_die

      t.timestamps
    end
  end
end
