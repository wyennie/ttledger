class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:campaign_id]}_#{params[:page_slug]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
