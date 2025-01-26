class ChatMessage < ApplicationRecord
  belongs_to :page
  belongs_to :campaign
  belongs_to :user

  after_create :broadcast_message
  after_update :broadcast_message

  def broadcast_message
    broadcast_append_to [
      "chat_#{campaign.id}_#{page.slug}_messages", # Turbo Stream target
      target: "chat_messages" # or define another target if necessary
    ], target: "chat_messages", partial: "chat/messages", locals: { message: self }
  end
end
