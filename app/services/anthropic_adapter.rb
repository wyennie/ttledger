class AnthropicAdapter
  CHAT_MODEL = :"claude-haiku-4-5"
  INGEST_MODEL = :"claude-sonnet-4-6"
  CHAT_MAX_TOKENS = 4096
  INGEST_MAX_TOKENS = 16_000

  def initialize(api_key)
    @client = Anthropic::Client.new(api_key: api_key)
  end

  def stream_chat(system:, messages:, &on_token)
    params = { model: CHAT_MODEL, max_tokens: CHAT_MAX_TOKENS, messages: messages }
    if system.present?
      params[:system_] = [ cacheable_text(system) ]
    end

    @client.messages.stream(**params).text.each(&on_token)
  end

  # Non-streaming structured-output call. Forces the model to invoke a single
  # named tool by passing tool_choice: { type: :tool, name: ... }; the caller
  # gets back the parsed tool input as a Hash.
  #
  # `system_blocks` should be an array of {text:, cache:} hashes so the caller
  # controls which blocks get cache_control. Large, reusable context (e.g. the
  # full PDF text) should have cache: true to be cheap on subsequent calls.
  def call_tool(system_blocks:, messages:, tool:, model: INGEST_MODEL, max_tokens: INGEST_MAX_TOKENS)
    params = {
      model: model,
      max_tokens: max_tokens,
      system_: system_blocks.map { |b| cacheable_text(b[:text], cache: b[:cache]) },
      messages: messages,
      tools: [ tool ],
      tool_choice: { type: :tool, name: tool[:name] }
    }

    response = @client.messages.create(params)
    extract_tool_input(response, tool[:name])
  end

  private

    def cacheable_text(text, cache: true)
      block = { type: "text", text: text }
      block[:cache_control] = { type: "ephemeral" } if cache
      block
    end

    def extract_tool_input(message, tool_name)
      block = message.content.find do |b|
        b.respond_to?(:type) && b.type.to_s == "tool_use" && b.name == tool_name
      end

      raise ToolCallMissing, "Model did not invoke `#{tool_name}`" unless block

      input = block.input
      input.is_a?(Hash) ? input.deep_symbolize_keys : input
    end

  class ToolCallMissing < StandardError; end
end
