class GetAiResponse < ApplicationJob
  def perform(chat_id, user_id)
    chat = Chat.find(chat_id)
    user = User.find(user_id)

    resolution = LLMResolver.client_for(user)

    system_prompt = chat.messages.where(message_role: :system).pluck(:content).join("\n\n")
    conversation = chat.messages
      .where(message_role: [ :user, :assistant ])
      .map { |m| { role: m.message_role, content: m.content } }

    assistant = chat.messages.create!(message_role: :assistant, content: "", response_number: 0)
    assistant.broadcast_created

    begin
      resolution.adapter.stream_chat(system: system_prompt, messages: conversation) do |token|
        assistant.update(content: assistant.content + token)
      end
    rescue Anthropic::Errors::APIError, Faraday::Error => e
      assistant.update(content: "_The #{resolution.provider.to_s.capitalize} API returned an error: #{provider_error_message(e)}_")
      raise
    rescue StandardError => e
      assistant.update(content: "_Something went wrong while generating a response. Please try again._")
      raise
    end
  rescue LLMResolver::QuotaExceeded
    chat.messages.create!(
      message_role: :assistant,
      content: "Demo quota reached for today. Add your own Anthropic or OpenAI API key in settings to keep chatting."
    )
  end

  private

    def provider_error_message(error)
      if error.respond_to?(:body) && error.body.is_a?(Hash)
        error.body.dig(:error, :message) || error.message
      elsif error.respond_to?(:response) && error.response.is_a?(Hash)
        error.response.dig(:body, "error", "message") || error.message
      else
        error.message
      end
    end
end
