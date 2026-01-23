class OpenAIAdapter
  MODEL = "gpt-4o-mini-2024-07-18"

  def initialize(api_key)
    @client = OpenAI::Client.new(access_token: api_key, log_errors: true)
  end

  def stream_chat(system:, messages:, &on_token)
    full_messages = system.present? ? [ { role: "system", content: system } ] + messages : messages
    @client.chat(
      parameters: {
        model: MODEL,
        messages: full_messages,
        temperature: 0.8,
        stream: ->(chunk, _bytesize) {
          token = chunk.dig("choices", 0, "delta", "content")
          on_token.call(token) if token
        }
      }
    )
  end
end
