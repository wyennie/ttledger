require 'rails_helper'

RSpec.describe AnthropicAdapter do
  let(:adapter) { described_class.new("sk-fake") }

  describe "#call_tool" do
    let(:tool) do
      {
        name: "emit_outline",
        description: "Emit the proposed outline.",
        input_schema: {
          type: "object",
          properties: {
            pages: { type: "array", items: { type: "object" } }
          },
          required: [ "pages" ]
        }
      }
    end

    it "forces the model to call the tool, sets cache control, and returns the parsed input as symbolized hash" do
      tool_use_block = double(
        "ToolUseBlock",
        type: :tool_use,
        name: "emit_outline",
        input: { "pages" => [ { "title" => "Chapter 1" } ] }
      )
      message = double("Message", content: [ tool_use_block ])

      messages_resource = double("messages")
      allow_any_instance_of(Anthropic::Client).to receive(:messages).and_return(messages_resource)

      expect(messages_resource).to receive(:create) do |params|
        expect(params[:model]).to eq(:"claude-sonnet-4-6")
        expect(params[:tool_choice]).to eq({ type: :tool, name: "emit_outline" })
        expect(params[:tools]).to eq([ tool ])
        expect(params[:system_]).to be_an(Array)
        expect(params[:system_].first[:cache_control]).to eq({ type: "ephemeral" })
        expect(params[:system_].last[:cache_control]).to be_nil
        message
      end

      result = adapter.call_tool(
        system_blocks: [
          { text: "Big PDF text", cache: true },
          { text: "Per-call instructions", cache: false }
        ],
        messages: [ { role: "user", content: "go" } ],
        tool: tool
      )

      expect(result).to eq(pages: [ { title: "Chapter 1" } ])
    end

    it "raises when the response has no tool_use block" do
      message = double("Message", content: [ double(type: :text) ])
      messages_resource = double("messages", create: message)
      allow_any_instance_of(Anthropic::Client).to receive(:messages).and_return(messages_resource)

      expect {
        adapter.call_tool(
          system_blocks: [ { text: "ctx", cache: true } ],
          messages: [ { role: "user", content: "go" } ],
          tool: { name: "emit_outline", description: "x", input_schema: { type: "object" } }
        )
      }.to raise_error(AnthropicAdapter::ToolCallMissing)
    end
  end
end
