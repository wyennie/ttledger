class ChatMessage < ApplicationRecord
  belongs_to :page
  belongs_to :campaign
  belongs_to :user
end
