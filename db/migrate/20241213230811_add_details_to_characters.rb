class AddDetailsToCharacters < ActiveRecord::Migration[8.0]
  def change
    add_column :characters, :occupation, :string
    add_column :characters, :title, :string
    add_column :characters, :character_class, :string
    add_column :characters, :alignment, :string
    add_column :characters, :speed, :integer
    add_column :characters, :level, :integer
    add_column :characters, :xp, :integer
  end
end
