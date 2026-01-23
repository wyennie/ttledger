require "rails_helper"

RSpec.describe LLMResolver do
  let(:user) { create(:user) }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }

  before { allow(Rails).to receive(:cache).and_return(cache) }

  describe ".client_for" do
    context "when the user has their own Anthropic key" do
      before { user.update!(anthropic_api_key: "sk-ant-abc") }

      it "returns using_demo: false with Anthropic provider" do
        result = described_class.client_for(user)
        expect(result.using_demo).to be false
        expect(result.provider).to eq(:anthropic)
        expect(result.adapter).to be_a(AnthropicAdapter)
      end

      it "does not increment the demo quota" do
        described_class.client_for(user)
        expect(cache.read("llm_demo_quota:#{user.id}:#{Date.current}")).to be_nil
      end
    end

    context "when the user has only an OpenAI key" do
      before { user.update!(openai_api_key: "sk-user-abc") }

      it "returns the OpenAI adapter" do
        result = described_class.client_for(user)
        expect(result.using_demo).to be false
        expect(result.provider).to eq(:openai)
        expect(result.adapter).to be_a(OpenAIAdapter)
      end
    end

    context "when the user has both keys" do
      before { user.update!(anthropic_api_key: "sk-ant-abc", openai_api_key: "sk-openai-abc") }

      it "prefers Anthropic" do
        result = described_class.client_for(user)
        expect(result.provider).to eq(:anthropic)
      end
    end

    context "when the user has no key and demo quota is available" do
      it "returns the demo Anthropic adapter and increments the quota" do
        result = described_class.client_for(user)
        expect(result.using_demo).to be true
        expect(result.provider).to eq(:anthropic)
        expect(cache.read("llm_demo_quota:#{user.id}:#{Date.current}")).to eq(1)
      end

      it "increments the quota across repeated calls" do
        3.times { described_class.client_for(user) }
        expect(cache.read("llm_demo_quota:#{user.id}:#{Date.current}")).to eq(3)
      end
    end

    context "when the demo quota is exhausted" do
      before do
        cache.write("llm_demo_quota:#{user.id}:#{Date.current}", described_class::DEMO_DAILY_LIMIT)
      end

      it "raises QuotaExceeded" do
        expect { described_class.client_for(user) }.to raise_error(described_class::QuotaExceeded)
      end
    end
  end
end
