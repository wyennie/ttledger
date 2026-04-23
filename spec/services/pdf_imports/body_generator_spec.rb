require 'rails_helper'

RSpec.describe PdfImports::BodyGenerator do
  let(:campaign) { create(:campaign) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:import) do
    create(:pdf_import,
           campaign: campaign,
           user: user,
           status: "expanding",
           extracted_pages: [ "page 1 raw", "page 2 raw" ],
           draft_payload: {
             "pages" => [
               { "tmp_id" => "p1", "title" => "Overview", "parent_tmp_id" => nil, "source_pages" => [ 1 ], "summary" => "Intro chapter" }
             ],
             "entities" => [
               { "tmp_id" => "e1", "name" => "Strahd", "kind" => "character", "summary" => "Vampire lord." }
             ]
           })
  end

  let(:adapter) { instance_double(AnthropicAdapter) }

  it "shares the cacheable PDF prefix and asks for HTML referencing entities by tmp_id" do
    expect(adapter).to receive(:call_tool) do |args|
      pdf_block = args[:system_blocks][0]
      expect(pdf_block[:cache]).to eq(true)
      expect(pdf_block[:text]).to include('<page n="1">').and include("page 1 raw")

      instructions = args[:system_blocks][1][:text]
      expect(instructions).to include("Overview")
      expect(instructions).to include("data-entity-tmp-id")
      expect(instructions).to include("e1")
      expect(instructions).to include("Strahd")
      expect(args[:tool][:name]).to eq("submit_body")
      expect(args[:model]).to eq(AnthropicAdapter::BODY_MODEL)

      { html_body: "<h2>Welcome</h2><p>Hello <span data-mention=\"entity\" data-entity-tmp-id=\"e1\">@Strahd</span>.</p>" }
    end

    html = described_class.call(import, page_tmp_id: "p1", adapter: adapter)
    expect(html).to include('data-entity-tmp-id="e1"')
  end

  it "raises if the requested page is not in the draft" do
    expect {
      described_class.call(import, page_tmp_id: "missing", adapter: adapter)
    }.to raise_error(ArgumentError, /missing/)
  end
end
