require 'rails_helper'

RSpec.describe ExpandDraftPageJob, type: :job do
  let(:campaign) { create(:campaign) }
  let(:user) { create(:user, confirmed_at: Time.current, anthropic_api_key: "sk-fake") }
  let(:import) do
    create(:pdf_import,
           campaign: campaign,
           user: user,
           status: "expanding",
           extracted_pages: [ "raw text" ],
           draft_payload: {
             "pages" => [
               { "tmp_id" => "p1", "title" => "Overview", "parent_tmp_id" => nil, "source_pages" => [ 1 ], "summary" => "intro" },
               { "tmp_id" => "p2", "title" => "World", "parent_tmp_id" => nil, "source_pages" => [ 1 ], "summary" => "world" }
             ]
           })
  end

  it "stores the generated body on the matching draft page" do
    allow(PdfImports::BodyGenerator).to receive(:call).and_return("<p>p1 body</p>")
    described_class.perform_now(import.id, "p1")

    page = import.reload.draft_payload["pages"].find { |p| p["tmp_id"] == "p1" }
    expect(page["body"]).to eq("<p>p1 body</p>")
    expect(import.status).to eq("expanding") # not all pages done yet
  end

  it "chains to the next page-without-body sequentially instead of fanning out" do
    allow(PdfImports::BodyGenerator).to receive(:call).and_return("<p>body</p>")
    expect(described_class).to receive(:perform_later).with(import.id, "p2")
    described_class.perform_now(import.id, "p1")
  end

  it "skips body generation if the page already has one and just chains forward" do
    import.draft_payload["pages"][0]["body"] = "<p>already done</p>"
    import.save!
    expect(PdfImports::BodyGenerator).not_to receive(:call)
    expect(described_class).to receive(:perform_later).with(import.id, "p2")
    described_class.perform_now(import.id, "p1")
  end

  it "transitions to ready_for_review when every page has a body" do
    allow(PdfImports::BodyGenerator).to receive(:call).and_return("<p>body</p>")
    described_class.perform_now(import.id, "p1")
    described_class.perform_now(import.id, "p2")

    expect(import.reload.status).to eq("ready_for_review")
  end

  it "skips when the import isn't expanding" do
    import.update!(status: "ready_for_review")
    expect(PdfImports::BodyGenerator).not_to receive(:call)
    described_class.perform_now(import.id, "p1")
  end

  it "marks the import failed when the generator raises" do
    allow(PdfImports::BodyGenerator).to receive(:call).and_raise(StandardError, "kaboom")
    expect {
      described_class.perform_now(import.id, "p1")
    }.to raise_error(StandardError)
    expect(import.reload).to be_failed
    expect(import.error_message).to include("kaboom")
  end
end
