require 'rails_helper'

RSpec.describe PdfImports::OutlineGenerator do
  let(:campaign) { create(:campaign) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:import) do
    create(:pdf_import,
           campaign: campaign,
           user: user,
           status: "outlining",
           extracted_pages: [ "Chapter 1\n...intro...", "Chapter 2\n...world..." ])
  end

  let(:adapter) { instance_double(AnthropicAdapter) }

  it "passes a cacheable PDF context block and the campaign's existing kinds, and returns the validated payload" do
    expect(adapter).to receive(:call_tool) do |args|
      pdf_block = args[:system_blocks][1]
      expect(pdf_block[:cache]).to eq(true)
      expect(pdf_block[:text]).to include('<page n="1">').and include("Chapter 1")

      instructions = args[:system_blocks][0][:text]
      expect(instructions).to include("character", "location") # default kinds
      expect(args[:tool][:name]).to eq("submit_outline")

      {
        pages: [
          { tmp_id: "p1", title: "Overview", parent_tmp_id: nil, source_pages: [ 1 ], summary: "Intro" },
          { tmp_id: "p2", title: "World", parent_tmp_id: "p1", source_pages: [ 2 ], summary: "World" }
        ],
        entities: [
          { tmp_id: "e1", name: "Strahd", kind: "Character", summary: "Vampire lord." }
        ]
      }
    end

    result = described_class.call(import, adapter: adapter)

    expect(result[:pages].size).to eq(2)
    expect(result[:pages][1][:parent_tmp_id]).to eq("p1")
    expect(result[:entities].first[:kind]).to eq("character") # normalized to lowercase
    expect(result[:entity_kinds]).to eq([ "character" ])
  end

  it "drops dangling parent_tmp_ids so a typo doesn't fail the import" do
    allow(adapter).to receive(:call_tool).and_return(
      pages: [ { tmp_id: "p1", title: "Lone", parent_tmp_id: "nonexistent", source_pages: [ 1 ], summary: "x" } ],
      entities: []
    )
    result = described_class.call(import, adapter: adapter)
    expect(result[:pages].first[:parent_tmp_id]).to be_nil
  end

  it "raises TooLarge when the PDF text would not fit in context" do
    huge = "x" * (described_class::MAX_INPUT_TOKENS * described_class::APPROX_CHARS_PER_TOKEN + 1000)
    import.update!(extracted_pages: [ huge ])
    expect {
      described_class.call(import, adapter: adapter)
    }.to raise_error(described_class::TooLarge, /tokens/)
  end
end
