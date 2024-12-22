class CampaignInvitation < ApplicationRecord
  belongs_to :campaign
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  enum :status, { pending: 0, accepted: 1, declined: 2 }

  validates :receiver_id, uniqueness: { scope: :campaign_id, message: "has already been invited to this campaign" }
end
