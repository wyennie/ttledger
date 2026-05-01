class AnthropicAdapter
  MODEL = :"claude-haiku-4-5"
  MAX_TOKENS = 4096

  def initialize(api_key)
    @client = Anthropic::Client.new(api_key: api_key)
  end

  def stream_chat(system:, messages:, &on_token)
    params = { model: MODEL, max_tokens: MAX_TOKENS, messages: messages }
    if system.present?
      params[:system_] = [
        { type: "text", text: system, cache_control: { type: "ephemeral" } }
      ]
    end

    @client.messages.stream(**params).text.each(&on_token)
  end
end
