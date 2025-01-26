class GetAiResponse < ApplicationJob
  RESPONSES_PER_MESSAGE = 1

  def perform(chat_id)
    chat = Chat.find(chat_id)
    call_openai(chat: chat)
  end

  private

  def call_openai(chat:)
    client = OpenAI::Client.new(
        access_token: Rails.application.credentials.open_ai_api_key,
        log_errors: true
      )
    client.chat(
      parameters: {
        model: "gpt-4",
        messages: Message.for_openai(chat.messages),
        temperature: 0.8,
        stream: stream_proc(chat: chat),
        n: RESPONSES_PER_MESSAGE
      }
    )
  end

  def create_messages(chat:)
    messages = []
    RESPONSES_PER_MESSAGE.times do |i|
      message = chat.messages.create(message_role: "assistant", content: "", response_number: i)
      message.broadcast_created
      messages << message
    end
    messages
  end

  def stream_proc(chat:)
    messages = create_messages(chat: chat)
    proc do |chunk, _bytesize|
      new_content = chunk.dig("choices", 0, "delta", "content")
      message = messages.find { |m| m.response_number == chunk.dig("choices", 0, "index") }
      message.update(content: message.content + new_content) if new_content
    end
  end

  
end
