class AddAnthropicApiKeyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :anthropic_api_key, :string
  end
end
