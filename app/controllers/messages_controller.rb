class MessagesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_chat

  def create
    @message = Message.create(message_params.merge(chat_id: params[:chat_id], message_role: "user"))

    GetAiResponse.perform_later(@message.chat_id)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy_all
    @chat.messages.destroy_all

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
