class ChatService
  attr_reader :message

  def initialize(message:, context:)
    @message = message
    @context = context
  end

  def call
    messages = training_prompts.map do |prompt|
      { role: "user", content: prompt }
    end

    messages << { role: "user", content: message }

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini-2024-07-18",
        messages: messages,
        temperature: 0.7
      }
    )
    # Extract the response content from the API response
    bot_message = response.dig("choices", 0, "message", "content")

    # Return the user message and bot message together
    { user_message: message, bot_message: bot_message }
  end

  private


    def training_prompts
      [
        "Do you know what tabletop roleplaying games are? Your job is to assist the game master",
        @context
      ]
    end

    def client
      @_client ||= OpenAI::Client.new(
        access_token: Rails.application.credentials.open_ai_api_key,
        log_errors: true
      )
    end
end
