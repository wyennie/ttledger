class LLMResolver
  DEMO_DAILY_LIMIT = 10

  class QuotaExceeded < StandardError; end

  Result = Struct.new(:adapter, :using_demo, :provider, keyword_init: true)

  def self.client_for(user)
    new(user).client_for
  end

  def initialize(user)
    @user = user
  end

  def client_for
    if @user.anthropic_api_key.present?
      Result.new(adapter: AnthropicAdapter.new(@user.anthropic_api_key), using_demo: false, provider: :anthropic)
    elsif @user.openai_api_key.present?
      Result.new(adapter: OpenAIAdapter.new(@user.openai_api_key), using_demo: false, provider: :openai)
    else
      raise QuotaExceeded if demo_quota_exhausted?
      increment_demo_quota
      Result.new(adapter: AnthropicAdapter.new(demo_anthropic_key), using_demo: true, provider: :anthropic)
    end
  end

  private

    def demo_anthropic_key
      ENV["ANTHROPIC_API_KEY"].presence || Rails.application.credentials.anthropic_api_key
    end

    def demo_quota_exhausted?
      quota_count >= DEMO_DAILY_LIMIT
    end

    def quota_count
      Rails.cache.read(quota_key) || 0
    end

    def increment_demo_quota
      Rails.cache.write(quota_key, quota_count + 1, expires_in: 25.hours)
    end

    def quota_key
      "llm_demo_quota:#{@user.id}:#{Date.current}"
    end
end
