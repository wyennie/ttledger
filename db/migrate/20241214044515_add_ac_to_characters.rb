class AddAcToCharacters < ActiveRecord::Migration[8.0]
  def change
    add_column :characters, :ac, :integer
  end
end
