require 'rails_helper'

RSpec.describe GenerateOutlineJob, type: :job do
  let(:campaign) { create(:campaign) }
  let(:user) { create(:user, confirmed_at: Time.current, anthropic_api_key: "sk-fake") }
  let(:import) do
    create(:pdf_import,
           campaign: campaign,
           user: user,
           status: "outlining",
           extracted_pages: [ "page 1 text", "page 2 text" ])
  end

  let(:fake_payload) do
    {
      pages: [ { tmp_id: "p1", title: "Overview", parent_tmp_id: nil, source_pages: [ 1, 2 ], summary: "x" } ],
      entities: [],
      entity_kinds: []
    }
  end

  it "writes the outline to draft_payload and advances to ready_for_review" do
    allow(PdfImports::OutlineGenerator).to receive(:call).and_return(fake_payload)

    described_class.perform_now(import.id)

    import.reload
    expect(import.status).to eq("ready_for_review")
    expect(import.draft_payload["pages"].first["title"]).to eq("Overview")
  end

  it "skips when import is no longer in outlining state" do
    import.update!(status: "ready_for_review")
    expect(PdfImports::OutlineGenerator).not_to receive(:call)
    described_class.perform_now(import.id)
  end

  it "marks the import failed when the generator raises TooLarge" do
    allow(PdfImports::OutlineGenerator).to receive(:call)
      .and_raise(PdfImports::OutlineGenerator::TooLarge, "too big")
    described_class.perform_now(import.id)
    expect(import.reload).to be_failed
    expect(import.error_message).to include("too big")
  end

  it "marks the import failed when no pages came back" do
    allow(PdfImports::OutlineGenerator).to receive(:call).and_return(pages: [], entities: [], entity_kinds: [])
    described_class.perform_now(import.id)
    expect(import.reload).to be_failed
  end
end
