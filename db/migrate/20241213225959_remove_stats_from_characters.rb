class RemoveStatsFromCharacters < ActiveRecord::Migration[8.0]
  def change
    remove_column :characters, :stats, :json
  end
end
