class CreateCampaignInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :campaign_invitations do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :receiver, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
